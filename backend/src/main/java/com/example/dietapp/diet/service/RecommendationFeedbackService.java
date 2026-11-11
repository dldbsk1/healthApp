package com.example.dietapp.diet.service;

import com.example.dietapp.diet.entity.DietMenu;
import com.example.dietapp.diet.entity.RecommendationEvent;
import com.example.dietapp.diet.entity.RecommendationEvent.Status;
import com.example.dietapp.diet.entity.UserPreference;
import com.example.dietapp.diet.repository.DietMenuRepository;
import com.example.dietapp.diet.repository.RecommendationEventRepository;
import com.example.dietapp.diet.repository.UserPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 추천 피드백 개인화
 *  - recordShown: 직전 추천 미반응 → SKIPPED(-0.4)
 *  - onLogged: 최근 추천 메뉴 기록 → LOGGED(+1.0)
 *  - TAG:*, ITEM:* 가중치, 30일 반감기
 */
@Service
@RequiredArgsConstructor
public class RecommendationFeedbackService {

    public static final double LOGGED_DELTA = 1.0;
    public static final double SKIPPED_DELTA = -0.4;

    private static final long SKIP_WINDOW_MINUTES = 30;   // 건너뜀 인정 시간
    private static final long LOG_WINDOW_MINUTES = 120;   // 추천 → 기록 인정 시간
    private static final double HALF_LIFE_DAYS = 30.0;
    private static final double MAX_ABS_WEIGHT = 3.0;
    private static final int FULL_PERSONALIZATION_EVENTS = 20;

    private final RecommendationEventRepository eventRepository;
    private final UserPreferenceRepository preferenceRepository;
    private final DietMenuRepository dietMenuRepository;

    public record Personalization(Map<String, Double> weights, double lambda) {
        public static final Personalization NONE = new Personalization(Map.of(), 0.0);

        /** -1 ~ +1 (태그 평균 + tanh) */
        public double score(DietMenu menu) {
            if (lambda <= 0) return 0.0;
            List<String> tags = menu.tagList();
            double tagMean = tags.isEmpty() ? 0.0
                    : tags.stream().mapToDouble(t -> weights.getOrDefault("TAG:" + t, 0.0)).average().orElse(0.0);
            double item = weights.getOrDefault("ITEM:" + menu.getFoodName(), 0.0);
            return Math.tanh(0.5 * tagMean + 0.5 * item);
        }
    }

    @Transactional(readOnly = true)
    public Personalization load(Long userId) {
        LocalDateTime now = LocalDateTime.now();
        Map<String, Double> weights = new HashMap<>();
        for (UserPreference pref : preferenceRepository.findByUserId(userId)) {
            weights.put(pref.getPrefKey(), decay(pref.getWeight(), pref.getUpdatedAt(), now));
        }
        long events = eventRepository.countByUserIdAndStatusIn(userId, List.of(Status.LOGGED, Status.SKIPPED));
        double lambda = Math.min(1.0, events / (double) FULL_PERSONALIZATION_EVENTS);
        return new Personalization(weights, lambda);
    }

    /** 최근 추천 메뉴 (최신순 5개) */
    @Transactional(readOnly = true)
    public List<String> recentShownFoods(Long userId, String context) {
        return eventRepository.findTop5ByUserIdAndContextOrderByShownAtDesc(userId, context).stream()
                .map(RecommendationEvent::getFoodName)
                .toList();
    }

    /** 추천 이력 저장 + 직전 추천 SKIPPED / EXPIRED 처리 */
    @Transactional
    public RecommendationEvent recordShown(Long userId, String context, String foodName) {
        LocalDateTime now = LocalDateTime.now();

        eventRepository.findTopByUserIdAndContextOrderByShownAtDesc(userId, context)
                .filter(prev -> prev.getStatus() == Status.SHOWN)
                .ifPresent(prev -> {
                    if (prev.getShownAt().isAfter(now.minusMinutes(SKIP_WINDOW_MINUTES))) {
                        prev.setStatus(Status.SKIPPED);
                        applyDelta(userId, prev.getFoodName(), SKIPPED_DELTA, now);
                    } else {
                        prev.setStatus(Status.EXPIRED);   // 오래된 추천은 무시
                    }
                    prev.setResolvedAt(now);
                    eventRepository.save(prev);
                });

        RecommendationEvent event = new RecommendationEvent();
        event.setUserId(userId);
        event.setContext(context);
        event.setFoodName(foodName);
        event.setShownAt(now);
        return eventRepository.save(event);
    }

    /** 추천 메뉴 기록 시 긍정 피드백 */
    @Transactional
    public void onLogged(Long userId, String foodName, Long recommendationId) {
        if (foodName == null || foodName.isBlank()) return;
        String name = foodName.trim();
        LocalDateTime now = LocalDateTime.now();

        RecommendationEvent event = null;
        if (recommendationId != null) {
            event = eventRepository.findById(recommendationId)
                    .filter(e -> e.getUserId().equals(userId) && name.equals(e.getFoodName()))
                    .orElse(null);
        }
        if (event == null) {
            // id 없으면 최근 추천 이름으로 매칭
            event = eventRepository
                    .findTopByUserIdAndFoodNameAndStatusInAndShownAtAfterOrderByShownAtDesc(
                            userId, name, List.of(Status.SHOWN, Status.SKIPPED), now.minusMinutes(LOG_WINDOW_MINUTES))
                    .orElse(null);
        }
        if (event == null || event.getStatus() == Status.LOGGED) return;

        // SKIPPED → LOGGED: 감점 복구 + 가점
        double delta = LOGGED_DELTA - (event.getStatus() == Status.SKIPPED ? SKIPPED_DELTA : 0.0);
        event.setStatus(Status.LOGGED);
        event.setResolvedAt(now);
        eventRepository.save(event);
        applyDelta(userId, event.getFoodName(), delta, now);
    }

    private void applyDelta(Long userId, String foodName, double delta, LocalDateTime now) {
        DietMenu menu = dietMenuRepository.findByFoodName(foodName).orElse(null);
        if (menu == null) return;   // 내부 DB 메뉴만 학습
        for (String tag : menu.tagList()) {
            addWeight(userId, "TAG:" + tag, delta, now);
        }
        addWeight(userId, "ITEM:" + foodName, delta, now);
    }

    private void addWeight(Long userId, String key, double delta, LocalDateTime now) {
        UserPreference pref = preferenceRepository.findByUserIdAndPrefKey(userId, key).orElseGet(() -> {
            UserPreference created = new UserPreference();
            created.setUserId(userId);
            created.setPrefKey(key);
            created.setWeight(0.0);
            return created;
        });
        double current = decay(pref.getWeight(), pref.getUpdatedAt(), now);   // 감쇠 후 누적
        pref.setWeight(Math.max(-MAX_ABS_WEIGHT, Math.min(MAX_ABS_WEIGHT, current + delta)));
        pref.setUpdatedAt(now);
        preferenceRepository.save(pref);
    }

    private static double decay(double weight, LocalDateTime updatedAt, LocalDateTime now) {
        if (updatedAt == null) return weight;
        double days = Math.max(0, Duration.between(updatedAt, now).toMinutes()) / 1440.0;
        return weight * Math.pow(0.5, days / HALF_LIFE_DAYS);
    }
}