package com.example.dietapp.user.dto;

public record SignupRequest(
        String email,
        String password,
        String nickname,
        String gender,
        Integer age,
        Double height,
        Double weight,
        Double targetWeight,
        String activityLevel,
        String goal,
        String dietPreference,
        Integer recommendedCalories
) {
}
