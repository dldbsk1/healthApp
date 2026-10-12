package com.example.diettotalbackend.dto;

import lombok.Data;

@Data
public class UserMenuRequest {
    private String userId;
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
}