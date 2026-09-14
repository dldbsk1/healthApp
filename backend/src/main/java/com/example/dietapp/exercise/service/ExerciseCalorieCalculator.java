package com.example.dietapp.exercise.service;

import java.util.Map;

/**
 * MET(대사당량) 기반 칼로리 추정.
 * 칼로리(kcal) = MET × 체중(kg) × 운동시간(시간)
 *
 * MET 값은 Compendium of Physical Activities 기준 대략적인 추정치입니다.
 * 실측 데이터가 쌓이면 운동별로 조정하세요.
 */
public final class ExerciseCalorieCalculator {

    private static final Map<String, Double> MET_TABLE = Map.of(
            "레그레이즈", 3.8,   // 복근 운동, 중강도
            "런지", 5.0,        // 하체 저항 운동
            "플랭크", 3.5,      // 등척성 코어 운동
            "푸쉬업", 8.0        // 전신 체중 저항 운동, 고강도
    );

    private static final double DEFAULT_MET = 4.0;         // 목록에 없는 운동명일 때 기본값
    private static final double DEFAULT_WEIGHT_KG = 60.0;   // 사용자 체중 정보가 없을 때 기본값

    private ExerciseCalorieCalculator() {
    }

    public static int estimate(String exerciseName, Integer durationMin, Double weightKg) {
        double met = MET_TABLE.getOrDefault(exerciseName, DEFAULT_MET);
        double weight = (weightKg != null) ? weightKg : DEFAULT_WEIGHT_KG;
        double hours = (durationMin != null ? durationMin : 0) / 60.0;
        return (int) Math.round(met * weight * hours);
    }
}