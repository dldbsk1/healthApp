package com.example.dietapp.alcohol.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class DrinkLogRequest {
    private String userId;          // 숫자 ID or 이메일
    private String drinkName;
    private Double amount;
    private LocalDateTime loggedAt; // null → 현재 시각
}
