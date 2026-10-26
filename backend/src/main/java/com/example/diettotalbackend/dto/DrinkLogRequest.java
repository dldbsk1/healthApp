package com.example.diettotalbackend.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class DrinkLogRequest {
    private String userId;          // 이메일 또는 숫자 ID
    private String drinkName;
    private Double amount;
    private LocalDateTime loggedAt; // 없으면 서버 현재 시각
}
