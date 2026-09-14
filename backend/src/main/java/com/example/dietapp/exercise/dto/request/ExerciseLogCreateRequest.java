package com.example.dietapp.exercise.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDateTime;

/**
 * 운동탭 - '운동 완료' 시 프론트에서 보내는 요청.
 * score/feedback/caloriesBurned 는 자세 분석 서버 결과가 아직 없으면 null 가능.
 */
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
