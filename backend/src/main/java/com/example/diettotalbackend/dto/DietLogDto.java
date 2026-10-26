package com.example.diettotalbackend.dto;

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
    private String unit; // amount의 단위 ("인분", "잔", "g")

    // ───── 추천 응답에서만 채워집니다 (폴백 메뉴는 null) ─────
    private Long recommendationId;               // 기록 저장 요청에 그대로 돌려보내면 피드백이 정확히 매칭됩니다 (선택)
    private String reason;                       // 화면에 보여줄 추천 이유 한 줄 (선택)
    private Map<String, Double> scoreBreakdown;  // 점수 분해 (발표/디버깅용)
}