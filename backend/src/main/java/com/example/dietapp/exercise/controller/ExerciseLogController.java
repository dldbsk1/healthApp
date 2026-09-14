package com.example.dietapp.exercise.controller;

import com.example.dietapp.exercise.dto.request.*;
import com.example.dietapp.exercise.dto.response.*;
import com.example.dietapp.exercise.service.ExerciseLogService;
import com.example.dietapp.global.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

/**
 * 운동탭 API.
 * TODO: JWT 인증 붙이면 @RequestParam Long userId → @AuthenticationPrincipal Long userId 로 되돌리기
 *       (JwtAuthenticationFilter 에서 Authentication.getPrincipal() 로 Long userId 를 세팅하는 방식)
 */
@RestController
@RequestMapping("/api/exercises/logs")
@RequiredArgsConstructor
public class ExerciseLogController {

    private final ExerciseLogService exerciseLogService;

    /** 운동 완료 시 기록 생성 */
    @PostMapping
    public ApiResponse<ExerciseLogResponse> createLog(
            @RequestParam Long userId,
            @Valid @RequestBody ExerciseLogCreateRequest request) {
        return ApiResponse.ok("운동 기록이 저장되었습니다.", exerciseLogService.createLog(userId, request));
    }

    /** 자세 분석 서버(YOLOv8-Pose+LSTM) 결과 반영 */
    @PatchMapping("/{exerciseLogId}/analysis")
    public ApiResponse<ExerciseLogResponse> updateAnalysisResult(
            @RequestParam Long userId,
            @PathVariable Long exerciseLogId,
            @Valid @RequestBody ExerciseAnalysisResultRequest request) {
        return ApiResponse.ok(exerciseLogService.updateAnalysisResult(userId, exerciseLogId, request));
    }

    /** 운동 기록 상세 (운동탭 '운동 분석 하러 가기') */
    @GetMapping("/{exerciseLogId}")
    public ApiResponse<ExerciseLogResponse> getLog(
            @RequestParam Long userId,
            @PathVariable Long exerciseLogId) {
        return ApiResponse.ok(exerciseLogService.getLog(userId, exerciseLogId));
    }

    /** 날짜별 운동 기록 목록 (기본값: 오늘) */
    @GetMapping
    public ApiResponse<List<ExerciseLogResponse>> getLogsByDate(
            @RequestParam Long userId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        LocalDate target = (date != null) ? date : LocalDate.now();
        return ApiResponse.ok(exerciseLogService.getLogsByDate(userId, target));
    }

    /** 홈탭 '오늘의 활동 요약' 중 운동 소모 칼로리 집계 */
    @GetMapping("/summary")
    public ApiResponse<ExerciseDailySummaryResponse> getDailySummary(
            @RequestParam Long userId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date,
            @RequestParam(defaultValue = "600") int targetExerciseCalorie) {
        LocalDate target = (date != null) ? date : LocalDate.now();
        return ApiResponse.ok(exerciseLogService.getDailySummary(userId, target, targetExerciseCalorie));
    }

    @DeleteMapping("/{exerciseLogId}")
    public ApiResponse<Void> deleteLog(
            @RequestParam Long userId,
            @PathVariable Long exerciseLogId) {
        exerciseLogService.deleteLog(userId, exerciseLogId);
        return ApiResponse.ok("삭제되었습니다.", null);
    }
}