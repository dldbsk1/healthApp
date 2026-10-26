package com.example.diettotalbackend.dto;

import lombok.Data;

@Data
public class UserUpdateRequest {
    private String email;
    private String password;
    private String nickname; // null이면 기존 닉네임 유지, 빈 문자열이면 닉네임 삭제
    private String gender;
    private int age;
    private double height;
    private double weight;
    private String activityLevel;
    private String goal;
    private String dietPreference;
    private int recommendedCalories;
}