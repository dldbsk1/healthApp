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
    public ResponseEntity<?> recordDiet(@RequestBody Map<String, Object> requestData) {
        try {
            return ResponseEntity.ok(dietLogService.saveDietLog(requestData));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
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

    // 🌟 [추가됨] 식단 기록 수정 API (PUT) — 본인(userId) 기록만 수정 가능
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

    // 🌟 [추가됨] 식단 기록 삭제 API (DELETE) — 본인(userId) 기록만 삭제 가능
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