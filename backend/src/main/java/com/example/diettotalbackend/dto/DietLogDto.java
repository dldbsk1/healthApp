package com.example.diettotalbackend.dto;

import lombok.Builder;
import lombok.Data;

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
}