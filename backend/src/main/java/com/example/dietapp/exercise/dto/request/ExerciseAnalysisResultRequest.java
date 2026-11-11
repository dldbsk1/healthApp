package com.example.dietapp.exercise.dto.request;

import jakarta.validation.constraints.NotNull;

/** 자세 분석 서버 결과 콜백 */
public record ExerciseAnalysisResultRequest(

        @NotNull
        Double score,

        String feedback,

        Integer caloriesBurned
) {
}
