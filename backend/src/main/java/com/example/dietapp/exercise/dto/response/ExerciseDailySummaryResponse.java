package com.example.dietapp.exercise.dto.response;

import java.time.LocalDate;

public record ExerciseDailySummaryResponse(
        LocalDate date,
        int totalCaloriesBurned,
        int targetExerciseCalorie,
        int totalDurationMin,
        long sessionCount
) {
}
