package com.example.dietapp.exercise.controller;

import com.example.dietapp.exercise.dto.request.*;
import com.example.dietapp.exercise.dto.response.*;
import com.example.dietapp.exercise.service.ExerciseLogService;
import com.example.dietapp.global.common.ApiResponse;
import com.example.dietapp.global.common.LogicalDay;
import jakarta.validation.Valid;
import com.example.dietapp.user.service.UserIdResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

/**
 * 운동탭 API (userId: 숫자 ID or 이메일)
 * TODO: JWT 적용 시 @AuthenticationPrincipal Long userId 로 교체
 */
@RestController
@RequestMapping("/api/exercises/logs")
@RequiredArgsConstructor
public class ExerciseLogController {

    private final ExerciseLogService exerciseLogService;
    private final UserIdResolver userIdResolver;

    @PostMapping
    public ApiResponse<ExerciseLogResponse> createLog(
            @RequestParam String userId,
            @Valid @RequestBody ExerciseLogCreateRequest request) {
        return ApiResponse.ok("운동 기록이 저장되었습니다.", exerciseLogService.createLog(userIdResolver.resolveId(userId), request));
    }

    /** 자세 분석 결과 반영 */
    @PatchMapping("/{exerciseLogId}/analysis")
    public ApiResponse<ExerciseLogResponse> updateAnalysisResult(
            @RequestParam String userId,
            @PathVariable Long exerciseLogId,
            @Valid @RequestBody ExerciseAnalysisResultRequest request) {
        return ApiResponse.ok(exerciseLogService.updateAnalysisResult(userIdResolver.resolveId(userId), exerciseLogId, request));
    }

    @GetMapping("/{exerciseLogId}")
    public ApiResponse<ExerciseLogResponse> getLog(
            @RequestParam String userId,
            @PathVariable Long exerciseLogId) {
        return ApiResponse.ok(exerciseLogService.getLog(userIdResolver.resolveId(userId), exerciseLogId));
    }

    /** 날짜별 목록 (기본: 오늘, 새벽 4시 기준) */
    @GetMapping
    public ApiResponse<List<ExerciseLogResponse>> getLogsByDate(
            @RequestParam String userId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        LocalDate target = (date != null) ? date : LogicalDay.today();
        return ApiResponse.ok(exerciseLogService.getLogsByDate(userIdResolver.resolveId(userId), target));
    }

    /** 홈탭 운동 요약 */
    @GetMapping("/summary")
    public ApiResponse<ExerciseDailySummaryResponse> getDailySummary(
            @RequestParam String userId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date,
            @RequestParam(defaultValue = "600") int targetExerciseCalorie) {
        LocalDate target = (date != null) ? date : LogicalDay.today();
        return ApiResponse.ok(exerciseLogService.getDailySummary(userIdResolver.resolveId(userId), target, targetExerciseCalorie));
    }

    @DeleteMapping("/{exerciseLogId}")
    public ApiResponse<Void> deleteLog(
            @RequestParam String userId,
            @PathVariable Long exerciseLogId) {
        exerciseLogService.deleteLog(userIdResolver.resolveId(userId), exerciseLogId);
        return ApiResponse.ok("삭제되었습니다.", null);
    }
}