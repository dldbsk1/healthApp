package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.service.DietLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/diet")
@RequiredArgsConstructor
public class DietLogController {

    private final DietLogService dietLogService;

    // ✅ 기존: 식단 기록 저장 API (수정 없음)
    @PostMapping("/log")
    public DietLog recordDiet(@RequestBody Map<String, Object> requestData) {
        return dietLogService.saveDietLog(requestData);
    }

    // 🌟 [추가됨] 하루 식단 목록 조회 API (GET)
    @GetMapping("/log")
    public ResponseEntity<List<DietLog>> getDailyLogs(
            @RequestParam("userId") String userId,
            @RequestParam("date") String date) {

        // 💡 중요: DietLogService에 아래 메서드가 없다면 새로 만들어주셔야 합니다!
        // (메서드 이름은 실제 Service에 만드신/만드실 이름에 맞게 변경하세요)
        List<DietLog> dailyLogs = dietLogService.findLogsByUserIdAndDate(userId, date);

        return ResponseEntity.ok(dailyLogs);
    }
}