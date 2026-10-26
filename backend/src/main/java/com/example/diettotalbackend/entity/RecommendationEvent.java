package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/** 추천 이력. 사용자가 이 추천에 어떻게 반응했는지(기록/건너뜀)가 개인화 학습의 신호가 됩니다. */
@Data
@Entity
@Table(name = "recommendation_events",
        indexes = @Index(name = "idx_rec_user_time", columnList = "user_id, shown_at"))
public class RecommendationEvent {

    public enum Status { SHOWN, SKIPPED, LOGGED, EXPIRED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    // 추천 맥락. 안주 추천은 "P|소주", 식단 추천은 "D|KETO"
    @Column(nullable = false, length = 100)
    private String context;

    @Column(nullable = false)
    private String foodName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status = Status.SHOWN;

    @Column(name = "shown_at", nullable = false)
    private LocalDateTime shownAt = LocalDateTime.now();

    private LocalDateTime resolvedAt;
}