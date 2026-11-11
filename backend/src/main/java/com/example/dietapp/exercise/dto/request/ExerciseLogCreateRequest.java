package com.example.dietapp.exercise.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.time.LocalDateTime;

/**
 * 운동탭 - '운동 완료' 시 프론트에서 보내는 요청.
 * score/feedback/caloriesBurned 는 자세 분석 서버 결과가 아직 없으면 null 가능.
 *
 * durationSec 는 칼로리 계산용 정확한 시간(초). 없으면(구버전 앱) durationMin × 60 으로 계산한다.
 * 0 도 허용한다 (플랭크를 한 번도 정상 자세로 못 버틴 경우 등).
 */
public record ExerciseLogCreateRequest(

        @NotBlank(message = "운동 이름은 필수입니다.")
        String exerciseName,

        @NotNull @Positive
        Integer durationMin,

        @PositiveOrZero
        Integer durationSec,

        Integer sets,

        Integer reps,

        Integer caloriesBurned,

        Double score,

        String feedback,

        @NotNull
        LocalDateTime exercisedAt
) {
}