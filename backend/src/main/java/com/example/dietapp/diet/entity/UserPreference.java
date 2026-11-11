package com.example.dietapp.diet.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/** 취향 가중치 (TAG:*, ITEM:*), 30일 반감기로 감쇠 */
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