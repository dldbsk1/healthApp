package com.example.dietapp.diet.entity;

import jakarta.persistence.*;
import tools.jackson.databind.annotation.JsonSerialize;
import tools.jackson.databind.ser.std.ToStringSerializer;
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

    // users.user_id
    @Column(name = "user_id", nullable = false)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    private String mealType;   // breakfast / lunch / dinner / snack
    @Column(nullable = false)
    private String foodName;
    private double amount;
    private double calories;
    private double carbs;
    private double protein;
    private double fat;
    @Column(length = 500)
    private String imageUrl;
    private LocalDateTime eatenAt;
    private LocalDateTime createdAt;
    private String unit;              // g / 인분 / 잔
}
