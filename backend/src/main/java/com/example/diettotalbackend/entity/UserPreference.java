package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 사용자별 취향 가중치 한 줄.
 * prefKey 예: "TAG:SPICY" (태그 선호), "ITEM:골뱅이 무침" (개별 메뉴 선호)
 * weight 는 저장 시점 기준 값이고, 읽을 때 반감기(30일)만큼 감쇠시켜 사용합니다.
 */
@Data
@Entity
@Table(name = "user_preferences",
        uniqueConstraints = @UniqueConstraint(name = "uk_user_pref", columnNames = {"user_id", "pref_key"}))
public class UserPreference {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "pref_key", nullable = false, length = 150)
    private String prefKey;

    private double weight;

    private LocalDateTime updatedAt = LocalDateTime.now();
}