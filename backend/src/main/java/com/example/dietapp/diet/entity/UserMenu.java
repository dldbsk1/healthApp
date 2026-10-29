package com.example.dietapp.diet.entity;

import jakarta.persistence.*;
import tools.jackson.databind.annotation.JsonSerialize;
import tools.jackson.databind.ser.std.ToStringSerializer;
import lombok.Data;

import java.time.LocalDateTime;

/** 내 메뉴 (본인 검색에만 노출, 1인분 기준) */
@Data
@Entity
@Table(name = "user_menus")
public class UserMenu {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Column(name = "user_id", nullable = false)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    @Column(nullable = false)
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    private LocalDateTime createdAt = LocalDateTime.now();
}
