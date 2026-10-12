package com.example.diettotalbackend.dto;

import lombok.Data;

@Data
public class UserUpdateRequest {
    private String email;
    private String password;
    private String gender;
    private int age;
    private double height;
    private double weight;
    private String activityLevel;
    private String goal;
    private String dietPreference;
    private int recommendedCalories;
}