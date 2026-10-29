package com.example.dietapp.user.dto;

/** email 로 조회, null 은 기존 값 유지 (nickname "" → 삭제) */
public record UserUpdateRequest(
        String email,
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
