package com.example.dietapp.exercise.dto.response;

import com.example.dietapp.exercise.entity.ExerciseLog;

import java.time.LocalDateTime;

public record ExerciseLogResponse(
        Long exerciseLogId,
        String exerciseName,
        Integer durationMin,
        Integer sets,
        Integer reps,
        Integer caloriesBurned,
        Double score,
        String feedback,
        LocalDateTime exercisedAt,
        LocalDateTime createdAt
) {
    public static ExerciseLogResponse from(ExerciseLog log) {
        return new ExerciseLogResponse(
                log.getId(),
                log.getExerciseName(),
                log.getDurationMin(),
                log.getSets(),
                log.getReps(),
                log.getCaloriesBurned(),
                log.getScore(),
                log.getFeedback(),
                log.getExercisedAt(),
                log.getCreatedAt()
        );
    }
}
