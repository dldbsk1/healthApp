package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.entity.RecommendationEvent;
import com.example.diettotalbackend.entity.RecommendationEvent.Status;
import com.example.diettotalbackend.entity.UserPreference;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.example.diettotalbackend.repository.RecommendationEventRepository;
import com.example.diettotalbackend.repository.UserPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 피드백 기반 개인화
 *  - 추천을 보여줄 때(recordShown): 같은 맥락의 직전 추천이 아직 반응 없이 남아 있으면 "다른 메뉴 추천"으로 보고 SKIPPED(-0.4)
 *  - 식단을 기록할 때(onLogged): 최근 추천했던 메뉴와 일치하면 LOGGED(+1.0)
 *  - 학습은 태그 단위(TAG:*)와 메뉴 단위(ITEM:*)로 하고, 읽을 때 30일 반감기로 감쇠
 */
@Service
@RequiredArgsConstructor
public class RecommendationFeedbackService {

    public static final double LOGGED_DELTA = 1.0;
    public static final double SKIPPED_DELTA = -0.4;

    private static final long SKIP_WINDOW_MINUTES = 30;   // 이 시간 안에 다시 요청해야 "건너뜀"으로 인정
    private static final long LOG_WINDOW_MINUTES = 120;   // 추천 후 이 시간 안에 기록하면 "추천을 따른 것"
    private static final double HALF_LIFE_DAYS = 30.0;
    private static final double MAX_ABS_WEIGHT = 3.0;
    private static final int FULL_PERSONALIZATION_EVENTS = 20;

    private final RecommendationEventRepository eventRepository;
    private final UserPreferenceRepository preferenceRepository;
    private final DietMenuRepository dietMenuRepository;

    /** 점수 계산 시점에 쓰는 읽기 전용 스냅샷 */
    public record Personalization(Map<String, Double> weights, double lambda) {
        public static final Personalization NONE = new Personalization(Map.of(), 0.0);

        /** -1 ~ +1. 태그는 평균을 내서 태그 개수가 많은 메뉴가 유리해지지 않게 하고, tanh 로 포화시킵니다. */
        public double score(DietMenu menu) {
            if (lambda <= 0) return 0.0;
            List<String> tags = menu.tagList();
            double tagMean = tags.isEmpty() ? 0.0
                    : tags.stream().mapToDouble(t -> weights.getOrDefault("TAG:" + t, 0.0)).average().orElse(0.0);
            double item = weights.getOrDefault("ITEM:" + menu.getFoodName(), 0.0);
            return Math.tanh(0.5 * tagMean + 0.5 * item);
        }
    }

    // ───────────── 읽기 ─────────────

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

    /** 같은 맥락에서 최근에 보여준 메뉴 이름 (최신순, 최대 5개). 최근 추천 감점에 사용합니다. */
    @Transactional(readOnly = true)
    public List<String> recentShownFoods(Long userId, String context) {
        return eventRepository.findTop5ByUserIdAndContextOrderByShownAtDesc(userId, context).stream()
                .map(RecommendationEvent::getFoodName)
                .toList();
    }

    // ───────────── 쓰기 ─────────────

    /** 추천을 내려주기 직전/직후에 호출. 새 추천 이력을 만들고, 직전 추천의 반응(건너뜀)을 반영합니다. */
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
                        prev.setStatus(Status.EXPIRED);   // 오래 지난 추천은 반응으로 치지 않음
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

    /** 식단 기록 저장 후 호출. 추천에서 온 기록이면 긍정 피드백을 반영합니다. */
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
            // recommendationId 가 없으면 "최근에 추천했던 같은 이름의 메뉴"로 매칭
            event = eventRepository
                    .findTopByUserIdAndFoodNameAndStatusInAndShownAtAfterOrderByShownAtDesc(
                            userId, name, List.of(Status.SHOWN, Status.SKIPPED), now.minusMinutes(LOG_WINDOW_MINUTES))
                    .orElse(null);
        }
        if (event == null || event.getStatus() == Status.LOGGED) return;

        // 건너뛰었다가 결국 기록했다면, 앞서 준 부정 점수를 되돌리고 긍정 점수를 줍니다.
        double delta = LOGGED_DELTA - (event.getStatus() == Status.SKIPPED ? SKIPPED_DELTA : 0.0);
        event.setStatus(Status.LOGGED);
        event.setResolvedAt(now);
        eventRepository.save(event);
        applyDelta(userId, event.getFoodName(), delta, now);
    }

    // ───────────── 내부 ─────────────

    private void applyDelta(Long userId, String foodName, double delta, LocalDateTime now) {
        DietMenu menu = dietMenuRepository.findByFoodName(foodName).orElse(null);
        if (menu == null) return;   // 내부 DB 메뉴가 아니면 학습하지 않음
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
        double current = decay(pref.getWeight(), pref.getUpdatedAt(), now);   // 저장 전에 먼저 감쇠
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