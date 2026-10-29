package com.example.dietapp.diet.controller;

import com.example.dietapp.diet.entity.DietLog;
import com.example.dietapp.diet.service.DietLogService;
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

    @PostMapping("/log")
    public ResponseEntity<?> recordDiet(@RequestBody Map<String, Object> requestData) {
        try {
            return ResponseEntity.ok(dietLogService.saveDietLog(requestData));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 오늘 기록 (date 미사용, 새벽 4시 기준)
    @GetMapping("/log")
    public ResponseEntity<List<DietLog>> getDailyLogs(
            @RequestParam("userId") String userId,
            @RequestParam("date") String date) {

        List<DietLog> dailyLogs = dietLogService.findLogsByUserIdAndDate(userId, date);

        return ResponseEntity.ok(dailyLogs);
    }

    // 본인 기록만 수정
    @PutMapping("/log/{id}")
    public ResponseEntity<?> updateLog(
            @PathVariable("id") Long id,
            @RequestBody Map<String, Object> requestData) {
        try {
            return ResponseEntity.ok(dietLogService.updateDietLog(id, requestData));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 본인 기록만 삭제
    @DeleteMapping("/log/{id}")
    public ResponseEntity<?> deleteLog(
            @PathVariable("id") Long id,
            @RequestParam("userId") String userId) {
        try {
            dietLogService.deleteDietLog(id, userId);
            return ResponseEntity.ok("삭제되었습니다.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}