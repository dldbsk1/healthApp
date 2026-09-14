package com.example.dietapp.exercise.service;

import com.example.dietapp.exercise.dto.request.*;
import com.example.dietapp.exercise.dto.response.*;
import com.example.dietapp.exercise.entity.ExerciseLog;
import com.example.dietapp.exercise.repository.ExerciseLogRepository;
import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import com.example.dietapp.global.exception.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExerciseLogService {

    private final ExerciseLogRepository exerciseLogRepository;
    private final UserRepository userRepository;

    /** 운동탭 - '운동 완료' 버튼 클릭 시 호출 */
    @Transactional
    public ExerciseLogResponse createLog(Long userId, ExerciseLogCreateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("존재하지 않는 사용자입니다. id=" + userId));

        Integer caloriesBurned = request.caloriesBurned();
        if (caloriesBurned == null) {
            caloriesBurned = ExerciseCalorieCalculator.estimate(
                    request.exerciseName(), request.durationMin(), user.getWeight());
        }

        ExerciseLog log = ExerciseLog.builder()
                .user(user)
                .exerciseName(request.exerciseName())
                .durationMin(request.durationMin())
                .sets(request.sets())
                .reps(request.reps())
                .caloriesBurned(caloriesBurned)
                .score(request.score())
                .feedback(request.feedback())
                .exercisedAt(request.exercisedAt())
                .build();

        return ExerciseLogResponse.from(exerciseLogRepository.save(log));
    }

    /** Python 자세 분석 서버의 결과를 뒤늦게 반영 (운동탭 '운동 분석 하러 가기') */
    @Transactional
    public ExerciseLogResponse updateAnalysisResult(Long userId, Long exerciseLogId,
                                                     ExerciseAnalysisResultRequest request) {
        ExerciseLog log = exerciseLogRepository.findByIdAndUserId(exerciseLogId, userId)
                .orElseThrow(() -> new EntityNotFoundException("운동 기록을 찾을 수 없습니다. id=" + exerciseLogId));

        log.updateAnalysisResult(request.score(), request.feedback(), request.caloriesBurned());
        return ExerciseLogResponse.from(log);
    }

    public ExerciseLogResponse getLog(Long userId, Long exerciseLogId) {
        ExerciseLog log = exerciseLogRepository.findByIdAndUserId(exerciseLogId, userId)
                .orElseThrow(() -> new EntityNotFoundException("운동 기록을 찾을 수 없습니다. id=" + exerciseLogId));
        return ExerciseLogResponse.from(log);
    }

    /** 날짜별 운동 기록 목록 (기본: 오늘) */
    public List<ExerciseLogResponse> getLogsByDate(Long userId, LocalDate date) {
        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = date.atTime(LocalTime.MAX);

        return exerciseLogRepository
                .findByUserIdAndExercisedAtBetweenOrderByExercisedAtDesc(userId, start, end)
                .stream()
                .map(ExerciseLogResponse::from)
                .toList();
    }

    /** 홈탭 '오늘의 활동 요약'용 집계 */
    public ExerciseDailySummaryResponse getDailySummary(Long userId, LocalDate date, int targetExerciseCalorie) {
        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = date.atTime(LocalTime.MAX);

        Integer totalCalories = exerciseLogRepository.sumCaloriesBurned(userId, start, end);
        Integer totalDuration = exerciseLogRepository.sumDurationMin(userId, start, end);
        long count = exerciseLogRepository.countByUserIdAndExercisedAtBetween(userId, start, end);

        return new ExerciseDailySummaryResponse(date, totalCalories, targetExerciseCalorie, totalDuration, count);
    }

    @Transactional
    public void deleteLog(Long userId, Long exerciseLogId) {
        ExerciseLog log = exerciseLogRepository.findByIdAndUserId(exerciseLogId, userId)
                .orElseThrow(() -> new EntityNotFoundException("운동 기록을 찾을 수 없습니다. id=" + exerciseLogId));
        exerciseLogRepository.delete(log);
    }
}
