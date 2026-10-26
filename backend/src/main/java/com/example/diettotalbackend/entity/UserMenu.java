package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 사용자가 직접 추가한 개인 메뉴 (user_menus 테이블)
 * - userId가 같은 사용자의 "음식 검색"에만 보입니다. (다른 사용자에게는 보이지 않고, 메뉴 추천에도 쓰이지 않음)
 * - 칼로리·탄단지는 1인분 기준이고, 입력하지 않은 값은 null입니다.
 */
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
