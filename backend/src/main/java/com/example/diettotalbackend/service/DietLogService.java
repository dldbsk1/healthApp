package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.repository.DietLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class DietLogService {

    private final DietLogRepository dietLogRepository;
    private final UserIdResolver userIdResolver;
    private final RecommendationFeedbackService feedbackService;

    // 1. 식단 저장: 프론트엔드에서 선택해서 넘겨준 식사 타입(mealType)을 그대로 DB에 저장합니다.
    //    추천에서 온 기록이면 피드백(+)을 남깁니다. requestData 에 recommendationId 가 있으면 정확히 매칭하고,
    //    없어도 최근 추천한 같은 이름의 메뉴로 매칭합니다.
    public DietLog saveDietLog(Map<String, Object> requestData) {
        Long userId = userIdResolver.resolveId(asString(requestData.get("userId")));
        LocalDateTime now = LocalDateTime.now();

        DietLog dietLog = DietLog.builder()
                .userId(userId)
                .mealType((String) requestData.get("mealType")) // 💡 프론트엔드가 고른 끼니 타입(아침, 점심 등)을 그대로 반영
                .foodName((String) requestData.get("foodName"))
                .amount(Double.valueOf(requestData.getOrDefault("amount", 1.0).toString()))
                .calories(Double.valueOf(requestData.get("calories").toString()))
                .carbs(Double.valueOf(requestData.get("carbs").toString()))
                .protein(Double.valueOf(requestData.get("protein").toString()))
                .fat(Double.valueOf(requestData.get("fat").toString()))
                .imageUrl((String) requestData.get("imageUrl"))
                .unit((String) requestData.get("unit")) // 💡 amount의 단위 (g / 인분 / 잔 / 병). 없으면 null
                .eatenAt(now)
                .createdAt(now)
                .build();

        DietLog saved = dietLogRepository.save(dietLog);

        // 피드백 학습이 실패해도 식단 기록 저장은 성공해야 하므로 예외를 삼킵니다.
        try {
            feedbackService.onLogged(userId, saved.getFoodName(), toLongOrNull(requestData.get("recommendationId")));
        } catch (Exception e) {
            log.warn("[추천 피드백] 반영 실패: {}", e.getClass().getSimpleName());
        }
        return saved;
    }

    // 2. 식단 조회: 서버 기준 '논리적 오늘' 반환
    public List<DietLog> findLogsByUserIdAndDate(String userIdentifier, String date) {
        Long userId = userIdResolver.findId(userIdentifier).orElse(null);
        if (userId == null) {
            return new ArrayList<>();
        }

        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();

        LocalDate logicalToday = now.toLocalDate();
        if (currentTime.isBefore(LocalTime.of(4, 0))) {
            logicalToday = logicalToday.minusDays(1);
        }

        LocalDateTime startOfLogicalDay = logicalToday.atTime(4, 0, 0);
        LocalDateTime endOfLogicalDay = logicalToday.plusDays(1).atTime(3, 59, 59, 999999000);

        return dietLogRepository.findByUserIdAndEatenAtBetween(userId, startOfLogicalDay, endOfLogicalDay);
    }

    // 3. 식단 수정: 기록한 본인(userId)만 수정할 수 있고, 먹은 시간(eatenAt)은 그대로 둡니다.
    public DietLog updateDietLog(Long id, Map<String, Object> requestData) {
        DietLog dietLog = findOwnedLog(id, asString(requestData.get("userId")));

        if (requestData.get("foodName") != null) {
            String foodName = ((String) requestData.get("foodName")).trim();
            if (foodName.isEmpty()) {
                throw new IllegalArgumentException("메뉴 이름을 입력해 주세요.");
            }
            dietLog.setFoodName(foodName);
        }
        if (requestData.get("mealType") != null) {
            dietLog.setMealType((String) requestData.get("mealType"));
        }
        if (requestData.get("amount") != null) dietLog.setAmount(toNonNegative(requestData.get("amount")));
        if (requestData.get("calories") != null) dietLog.setCalories(toNonNegative(requestData.get("calories")));
        if (requestData.get("carbs") != null) dietLog.setCarbs(toNonNegative(requestData.get("carbs")));
        if (requestData.get("protein") != null) dietLog.setProtein(toNonNegative(requestData.get("protein")));
        if (requestData.get("fat") != null) dietLog.setFat(toNonNegative(requestData.get("fat")));
        if (requestData.get("unit") != null) dietLog.setUnit((String) requestData.get("unit"));

        return dietLogRepository.save(dietLog);
    }

    // 4. 식단 삭제: 기록한 본인(userId)만 삭제할 수 있습니다.
    public void deleteDietLog(Long id, String userIdentifier) {
        DietLog dietLog = findOwnedLog(id, userIdentifier);
        dietLogRepository.delete(dietLog);
    }

    // 기록을 찾고, 요청한 사용자의 기록이 맞는지 확인
    private DietLog findOwnedLog(Long id, String userIdentifier) {
        DietLog dietLog = dietLogRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없어요."));
        Long userId = userIdResolver.findId(userIdentifier).orElse(null);
        if (userId == null || !userId.equals(dietLog.getUserId())) {
            throw new IllegalArgumentException("본인의 기록만 수정하거나 삭제할 수 있어요.");
        }
        return dietLog;
    }

    private double toNonNegative(Object value) {
        double number = Double.parseDouble(value.toString());
        if (number < 0) {
            throw new IllegalArgumentException("숫자는 0 이상이어야 해요.");
        }
        return number;
    }

    // userId가 문자열이든 숫자든(JSON 숫자) 문자열로 통일
    private String asString(Object value) {
        return value == null ? null : value.toString();
    }

    // recommendationId 는 숫자/문자열 어느 쪽으로 와도 받고, 이상한 값이면 무시(null)
    private Long toLongOrNull(Object value) {
        if (value == null) return null;
        try {
            return Long.valueOf(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}