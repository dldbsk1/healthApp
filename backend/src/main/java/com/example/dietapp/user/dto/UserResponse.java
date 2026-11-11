package com.example.dietapp.user.dto;

import com.example.dietapp.user.entity.User;

/** 비밀번호 제외, id 문자열, 숫자 null → 0 (기존 프론트 호환) */
public record UserResponse(
        String id,
        String email,
        String nickname,
        String gender,
        int age,
        double height,
        double weight,
        Double targetWeight,
        String activityLevel,
        String goal,
        String dietPreference,
        int recommendedCalories
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                String.valueOf(user.getId()),
                user.getEmail(),
                user.getNickname(),
                user.getGender(),
                orZero(user.getAge()),
                orZero(user.getHeight()),
                orZero(user.getWeight()),
                user.getTargetWeight(),
                user.getActivityLevel(),
                user.getGoal(),
                user.getDietPreference(),
                orZero(user.getRecommendedCalories())
        );
    }

    private static int orZero(Integer value) {
        return value == null ? 0 : value;
    }

    private static double orZero(Double value) {
        return value == null ? 0.0 : value;
    }
}
