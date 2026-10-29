package com.example.dietapp.exercise.service;

import com.example.dietapp.exercise.dto.request.*;
import com.example.dietapp.exercise.dto.response.*;
import com.example.dietapp.exercise.entity.ExerciseLog;
import com.example.dietapp.exercise.repository.ExerciseLogRepository;
import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import com.example.dietapp.global.common.LogicalDay;
import com.example.dietapp.global.exception.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExerciseLogService {

    private final ExerciseLogRepository exerciseLogRepository;
    private final UserRepository userRepository;

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

    public List<ExerciseLogResponse> getLogsByDate(Long userId, LocalDate date) {
        LocalDateTime start = LogicalDay.start(date);
        LocalDateTime end = LogicalDay.end(date);

        return exerciseLogRepository
                .findByUserIdAndExercisedAtBetweenOrderByExercisedAtDesc(userId, start, end)
                .stream()
                .map(ExerciseLogResponse::from)
                .toList();
    }

    public ExerciseDailySummaryResponse getDailySummary(Long userId, LocalDate date, int targetExerciseCalorie) {
        LocalDateTime start = LogicalDay.start(date);
        LocalDateTime end = LogicalDay.end(date);

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
