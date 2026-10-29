package com.example.dietapp.diet.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class FoodSearchResultDto {
    private String foodName;
    private String imageUrl;
    private double calories;   // kcal
    private double carbs;      // g
    private double protein;    // g
    private double fat;        // g
    private String source;       // 내 메뉴 / 식약처 / null(내부 DB)
    private String servingNote;  // 1인분 기준 안내
}