package com.example.dietapp.exercise.service;

import java.util.Locale;
import java.util.Map;

/**
 * 칼로리 = MET × 체중(kg) × 시간(h)  (MET: Compendium 기준 추정치)
 */
public final class ExerciseCalorieCalculator {

    private static final Map<String, Double> MET_TABLE = Map.of(
            "레그레이즈", 3.8,
            "런지", 5.0,
            "플랭크", 3.5,
            "푸쉬업", 8.0
    );

    private static final Map<String, Double> MAX_SEC_PER_REP = Map.of(
            "레그레이즈", 6.0,
            "런지", 6.0,
            "푸쉬업", 6.0
    );

    private static final String HOLD_EXERCISE = "플랭크";

    private static final double DEFAULT_MET = 4.0;
    private static final double DEFAULT_WEIGHT_KG = 60.0;

    private ExerciseCalorieCalculator() {
    }

    public static int estimate(String exerciseName, Integer durationMin, Double weightKg) {
        Double sec = (durationMin != null) ? durationMin * 60.0 : null;
        return estimate(exerciseName, sec, null, weightKg);
    }

    /**
     * @param durationSec 운동 시간(초). 플랭크는 화면에 표시된 유지 시간. null/0 이하면 0으로 본다.
     * @param reps        반복 횟수. 반복 운동에서 0이면 0kcal, null이면 횟수 없이 시간만으로 계산(구버전 앱 호환).
     * @param weightKg    사용자 체중. null 또는 0 이하면 기본 체중.
     */
    public static int estimate(String exerciseName, Double durationSec, Integer reps, Double weightKg) {
        String key = normalize(exerciseName);
        boolean hold = HOLD_EXERCISE.equals(key);

        double sec = (durationSec != null && durationSec > 0) ? durationSec : 0.0;

        if (!hold && reps != null) {
            if (reps <= 0) {
                return 0;
            }
            Double maxPerRep = MAX_SEC_PER_REP.get(key);
            if (maxPerRep != null) {
                sec = Math.min(sec, reps * maxPerRep);
            }
        }

        double met = MET_TABLE.getOrDefault(key, DEFAULT_MET);
        double weight = (weightKg != null && weightKg > 0) ? weightKg : DEFAULT_WEIGHT_KG;

        return (int) Math.round(met * weight * (sec / 3600.0));
    }

    static String normalize(String name) {
        if (name == null) {
            return "";
        }
        String n = name.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);

        if (n.contains("푸쉬업") || n.contains("푸시업") || n.contains("pushup") || n.contains("push-up")) {
            return "푸쉬업";
        }
        if (n.contains("레그레이즈") || n.contains("legraise") || n.contains("leg-raise")) {
            return "레그레이즈";
        }
        if (n.contains("런지") || n.contains("lunge")) {
            return "런지";
        }
        if (n.contains("플랭크") || n.contains("plank")) {
            return "플랭크";
        }
        return name.trim();
    }
}