package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
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
    private String drinkName; // 소주, 맥주 등
    private double amount;    // 1.5 (병/잔)
    private LocalDateTime loggedAt = LocalDateTime.now();
}
