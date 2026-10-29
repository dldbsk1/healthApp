package com.example.dietapp.exercise.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDateTime;

/** 운동 완료 요청 (분석 전이면 score / feedback / caloriesBurned null) */
public record ExerciseLogCreateRequest(

        @NotBlank(message = "운동 이름은 필수입니다.")
        String exerciseName,

        @NotNull @Positive
        Integer durationMin,

        Integer sets,

        Integer reps,

        Integer caloriesBurned,

        Double score,

        String feedback,

        @NotNull
        LocalDateTime exercisedAt
) {
}
