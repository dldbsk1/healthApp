package com.example.dietapp.diet.dto;

import lombok.Builder;
import lombok.Data;

import java.util.Map;

@Data
@Builder
public class DietLogDto {
    private String userId;
    private String mealType;
    private String foodName;
    private Double amount;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    private String imageUrl;
    private String eatenAt;
    private String unit; // 인분 / 잔 / g

    // 추천 응답 전용 (폴백 메뉴는 null)
    private Long recommendationId;               // 기록 저장 시 그대로 전달 → 피드백 매칭
    private String reason;                       // 추천 이유
    private Map<String, Double> scoreBreakdown;  // 점수 분해 (디버깅용)
}