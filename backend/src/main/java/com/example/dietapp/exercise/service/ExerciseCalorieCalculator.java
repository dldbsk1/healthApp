package com.example.dietapp.exercise.service;

import java.util.Map;

/** 칼로리 = MET × 체중(kg) × 시간(h) (MET: Compendium 기준 추정치) */
public final class ExerciseCalorieCalculator {

    private static final Map<String, Double> MET_TABLE = Map.of(
            "레그레이즈", 3.8,
            "런지", 5.0,
            "플랭크", 3.5,
            "푸쉬업", 8.0
    );

    private static final double DEFAULT_MET = 4.0;         // 미등록 운동
    private static final double DEFAULT_WEIGHT_KG = 60.0;   // 체중 미입력

    private ExerciseCalorieCalculator() {
    }

    public static int estimate(String exerciseName, Integer durationMin, Double weightKg) {
        double met = MET_TABLE.getOrDefault(exerciseName, DEFAULT_MET);
        double weight = (weightKg != null) ? weightKg : DEFAULT_WEIGHT_KG;
        double hours = (durationMin != null ? durationMin : 0) / 60.0;
        return (int) Math.round(met * weight * hours);
    }
}