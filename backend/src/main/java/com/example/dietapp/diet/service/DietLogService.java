package com.example.dietapp.diet.service;

import com.example.dietapp.diet.entity.DietLog;
import com.example.dietapp.diet.repository.DietLogRepository;
import com.example.dietapp.global.common.LogicalDay;
import com.example.dietapp.user.service.UserIdResolver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
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

    // 저장 + 추천 피드백 (recommendationId 또는 최근 추천 이름으로 매칭)
    public DietLog saveDietLog(Map<String, Object> requestData) {
        Long userId = userIdResolver.resolveId(asString(requestData.get("userId")));
        LocalDateTime now = LocalDateTime.now();

        DietLog dietLog = DietLog.builder()
                .userId(userId)
                .mealType((String) requestData.get("mealType"))
                .foodName((String) requestData.get("foodName"))
                .amount(requestData.get("amount") == null ? 1.0 : toNonNegative(requestData.get("amount")))
                .calories(requiredNumber(requestData, "calories"))
                .carbs(requiredNumber(requestData, "carbs"))
                .protein(requiredNumber(requestData, "protein"))
                .fat(requiredNumber(requestData, "fat"))
                .imageUrl((String) requestData.get("imageUrl"))
                .unit((String) requestData.get("unit"))
                .eatenAt(now)
                .createdAt(now)
                .build();

        DietLog saved = dietLogRepository.save(dietLog);

        // 피드백 실패해도 저장은 유지
        try {
            feedbackService.onLogged(userId, saved.getFoodName(), toLongOrNull(requestData.get("recommendationId")));
        } catch (Exception e) {
            log.warn("[추천 피드백] 반영 실패: {}", e.getClass().getSimpleName());
        }
        return saved;
    }

    // 오늘(새벽 4시 기준) 기록, date 미사용
    public List<DietLog> findLogsByUserIdAndDate(String userIdentifier, String date) {
        Long userId = userIdResolver.findId(userIdentifier).orElse(null);
        if (userId == null) {
            return new ArrayList<>();
        }

        LocalDate today = LogicalDay.today();
        return dietLogRepository.findByUserIdAndEatenAtBetween(userId, LogicalDay.start(today), LogicalDay.end(today));
    }

    // 본인만 수정, eatenAt 유지
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

    // 본인만 삭제
    public void deleteDietLog(Long id, String userIdentifier) {
        DietLog dietLog = findOwnedLog(id, userIdentifier);
        dietLogRepository.delete(dietLog);
    }

    private DietLog findOwnedLog(Long id, String userIdentifier) {
        DietLog dietLog = dietLogRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없어요."));
        Long userId = userIdResolver.findId(userIdentifier).orElse(null);
        if (userId == null || !userId.equals(dietLog.getUserId())) {
            throw new IllegalArgumentException("본인의 기록만 수정하거나 삭제할 수 있어요.");
        }
        return dietLog;
    }

    // 없거나 숫자 아니면 400
    private double requiredNumber(Map<String, Object> requestData, String key) {
        Object value = requestData.get(key);
        if (value == null) {
            throw new IllegalArgumentException(key + " 값이 필요해요.");
        }
        return toNonNegative(value);
    }

    private double toNonNegative(Object value) {
        double number;
        try {
            number = Double.parseDouble(value.toString().trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("숫자 형식이 올바르지 않아요: " + value);
        }
        if (number < 0) {
            throw new IllegalArgumentException("숫자는 0 이상이어야 해요.");
        }
        return number;
    }

    private String asString(Object value) {
        return value == null ? null : value.toString();
    }

    // 잘못된 값 → null
    private Long toLongOrNull(Object value) {
        if (value == null) return null;
        try {
            return Long.valueOf(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}