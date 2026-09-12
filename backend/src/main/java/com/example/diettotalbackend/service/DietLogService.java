package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.repository.DietLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DietLogService {

    private final DietLogRepository dietLogRepository;

    // 1. 식단 저장: 프론트엔드에서 선택해서 넘겨준 식사 타입(mealType)을 그대로 DB에 저장합니다.
    public DietLog saveDietLog(Map<String, Object> requestData) {
        LocalDateTime now = LocalDateTime.now();

        DietLog dietLog = DietLog.builder()
                .userId((String) requestData.get("userId"))
                .mealType((String) requestData.get("mealType")) // 💡 프론트엔드가 고른 끼니 타입(아침, 점심 등)을 그대로 반영
                .foodName((String) requestData.get("foodName"))
                .amount(Double.valueOf(requestData.getOrDefault("amount", 1.0).toString()))
                .calories(Double.valueOf(requestData.get("calories").toString()))
                .carbs(Double.valueOf(requestData.get("carbs").toString()))
                .protein(Double.valueOf(requestData.get("protein").toString()))
                .fat(Double.valueOf(requestData.get("fat").toString()))
                .imageUrl((String) requestData.get("imageUrl"))
                .eatenAt(now)
                .createdAt(now)
                .build();

        return dietLogRepository.save(dietLog);
    }

    // 2. 식단 조회: 서버 기준 '논리적 오늘' 반환
    public List<DietLog> findLogsByUserIdAndDate(String userId, String date) {
        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();

        LocalDate logicalToday = now.toLocalDate();
        if (currentTime.isBefore(LocalTime.of(4, 0))) {
            logicalToday = logicalToday.minusDays(1);
        }

        LocalDateTime startOfLogicalDay = logicalToday.atTime(4, 0, 0);
        LocalDateTime endOfLogicalDay = logicalToday.plusDays(1).atTime(3, 59, 59, 999999999);

        return dietLogRepository.findByUserIdAndEatenAtBetween(userId, startOfLogicalDay, endOfLogicalDay);
    }
}