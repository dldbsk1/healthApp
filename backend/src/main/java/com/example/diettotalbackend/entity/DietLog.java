package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "diet_logs")
public class DietLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    // users.user_id (숫자). 프론트가 이메일/숫자 ID 어느 쪽을 보내도 UserIdResolver가 변환합니다.
    @Column(name = "user_id", nullable = false)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    private String mealType;   // breakfast, lunch, dinner, snack
    @Column(nullable = false)
    private String foodName;
    private double amount;
    private double calories;
    private double carbs;
    private double protein;
    private double fat;
    @Column(length = 500)
    private String imageUrl;
    private LocalDateTime eatenAt;    // 먹은 시간
    private LocalDateTime createdAt;  // 기록한 시간
    private String unit;              // amount의 단위: "g"(사진 분석), "인분"(추천 메뉴), "잔"(술)
}
