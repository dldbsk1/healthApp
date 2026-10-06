package com.example.diettotalbackend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class FoodSearchResultDto {
    private String foodName;   // 음식 이름
    private String imageUrl;   // 사진 URL
    private double calories;   // 칼로리 (kcal)
    private double carbs;      // 탄수화물 (g)
    private double protein;    // 단백질 (g)
    private double fat;        // 지방 (g)
}