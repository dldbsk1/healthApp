package com.example.dietapp.exercise.dto.request;

import jakarta.validation.constraints.NotNull;

/**
 * Python 자세 분석(YOLOv8-Pose + LSTM) 서버가 분석을 마친 뒤
 * 콜백으로 점수/피드백/소모 칼로리를 갱신할 때 사용.
 */
public record ExerciseAnalysisResultRequest(

        @NotNull
        Double score,

        String feedback,

        Integer caloriesBurned
) {
}
