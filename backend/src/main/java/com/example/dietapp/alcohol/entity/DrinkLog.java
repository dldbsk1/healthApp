package com.example.dietapp.alcohol.entity;

import jakarta.persistence.*;
import tools.jackson.databind.annotation.JsonSerialize;
import tools.jackson.databind.ser.std.ToStringSerializer;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "drink_logs")
public class DrinkLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Column(name = "user_id", nullable = false)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    @Column(nullable = false)
    private String drinkName;
    private double amount;    // 병·잔
    private LocalDateTime loggedAt = LocalDateTime.now();
}
