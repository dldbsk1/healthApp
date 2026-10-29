package com.example.dietapp.diet.service;

import com.example.dietapp.diet.entity.DietLog;
import com.example.dietapp.diet.entity.DietMenu;
import com.example.dietapp.diet.service.RecommendationFeedbackService.Personalization;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * 메뉴 점수 + 소프트맥스 샘플링
 * total = tag + calorie + protein + diet + eaten + repeat + personal
 *   tag      : 선호 태그 +2.5, 회피 태그 -3, 묵직함 범위 내 +2 / 단계당 -1.5 (안주만)
 *   calorie  : 상한 70% 이하 +2, 이하 +1, 초과 -2
 *   protein  : 남은 단백질 보충 최대 +2
 *   diet     : 식단 유형 일치 +2 (안주만)
 *   eaten    : 오늘 먹은 메뉴 -10
 *   repeat   : 최근 추천 -8, -5, -3, -2, -1
 *   personal : λ × 3 × tanh(취향)
 */
@Component
public class MenuScorer {

    private static final double TAG_MATCH = 2.5, TAG_AVOID = -3.0;
    private static final double HEAVY_IN_RANGE = 2.0, HEAVY_PER_STEP = -1.5;
    private static final double CAL_LIGHT = 2.0, CAL_FIT = 1.0, CAL_OVER = -2.0;
    private static final double PROTEIN_MAX = 2.0, DIET_MATCH = 2.0;
    private static final double EATEN_TODAY = -10.0, PERSONAL_MAX = 3.0;
    /** 최근 추천 감점 (최신순) */
    private static final double[] RECENT_PENALTIES = {-8.0, -5.0, -3.0, -2.0, -1.0};

    private static final int TOP_K = 10;               // 샘플링 후보 수
    private static final double TEMPERATURE = 3.0;     // 클수록 균등
    private static final double EXPLORE_RATE = 0.10;   // 무작위 탐색 확률

    private final Random random = new Random();

    public record Context(String category, DrinkProfile profile, double maxCalories, List<DietLog> todayLogs,
                          String dietPreference, double remainingProtein, List<String> recentRecommended,
                          Personalization personalization) {}

    /** fits: 선호 태그 ≥ 1 && 회피 태그 < 선호 태그 */
    public record Breakdown(DietMenu menu, double tag, double calorie, double protein,
                            double diet, double eaten, double repeat, double personal, boolean fits) {

        public double total() {
            return tag + calorie + protein + diet + eaten + repeat + personal;
        }

        public Map<String, Double> asMap() {
            Map<String, Double> map = new LinkedHashMap<>();
            map.put("tag", r(tag));
            map.put("calorie", r(calorie));
            map.put("protein", r(protein));
            map.put("diet", r(diet));
            map.put("eaten", r(eaten));
            map.put("repeat", r(repeat));
            map.put("personal", r(personal));
            map.put("total", r(total()));
            return map;
        }

        /** 주요 가산 요인 → 추천 이유 */
        public String reason(String category) {
            List<String> parts = new ArrayList<>();
            if (tag >= 5.0 && category != null) parts.add(category + " 궁합");
            if (protein >= 1.0) parts.add("오늘 부족한 단백질 보충");
            if (personal >= 0.5) parts.add("평소 취향과 비슷해요");
            if (diet > 0) parts.add("내 식단 유형에 맞아요");
            if (calorie >= CAL_LIGHT) parts.add("남은 칼로리에 여유 있어요");
            return String.join(" · ", parts.subList(0, Math.min(3, parts.size())));
        }

        private static double r(double v) {
            return Math.round(v * 100.0) / 100.0;
        }
    }

    public Breakdown score(DietMenu m, Context c) {
        double tag = 0, diet = 0;
        boolean fits = true;

        DrinkProfile d = c.profile();
        if (d != null) {
            List<String> tags = m.tagList();
            long match = tags.stream().filter(d.prefer()::contains).count();
            long avoid = tags.stream().filter(d.avoid()::contains).count();
            tag = match * TAG_MATCH + avoid * TAG_AVOID;

            Integer h = m.getHeaviness();
            if (h != null) {
                int dist = h < d.minHeaviness() ? d.minHeaviness() - h
                        : (h > d.maxHeaviness() ? h - d.maxHeaviness() : 0);
                tag += dist == 0 ? HEAVY_IN_RANGE : dist * HEAVY_PER_STEP;
            }

            fits = match >= 1 && !(avoid > 0 && match <= avoid);

            if (c.dietPreference() != null && c.dietPreference().equalsIgnoreCase(m.getDietType())) {
                diet = DIET_MATCH;
            }
        }

        double cal = m.getCalories() == null ? 0.0 : m.getCalories();
        double ratio = c.maxCalories() > 0 ? cal / c.maxCalories() : 1.0;
        double calorie = ratio <= 0.7 ? CAL_LIGHT : (ratio <= 1.0 ? CAL_FIT : CAL_OVER);

        double protein = 0;
        if (c.remainingProtein() > 10 && m.getProtein() != null) {
            protein = PROTEIN_MAX * Math.min(1.0, m.getProtein() / (c.remainingProtein() * 0.5));
        }

        boolean eaten = m.getFoodName() != null && c.todayLogs().stream()
                .anyMatch(l -> l.getFoodName() != null && l.getFoodName().contains(m.getFoodName()));
        double eatenScore = eaten ? EATEN_TODAY : 0.0;

        int recentIdx = c.recentRecommended() == null ? -1 : c.recentRecommended().indexOf(m.getFoodName());
        double repeat = (recentIdx >= 0 && recentIdx < RECENT_PENALTIES.length) ? RECENT_PENALTIES[recentIdx] : 0.0;

        Personalization p = c.personalization() == null ? Personalization.NONE : c.personalization();
        double personal = p.lambda() * PERSONAL_MAX * p.score(m);

        return new Breakdown(m, tag, calorie, protein, diet, eatenScore, repeat, personal, fits);
    }

    /** 상위 K 소프트맥스 샘플링 + 일부 무작위 탐색 */
    public Breakdown select(List<Breakdown> scored) {
        if (scored == null || scored.isEmpty()) return null;

        List<Breakdown> sorted = scored.stream()
                .sorted(Comparator.comparingDouble(Breakdown::total).reversed())
                .toList();

        if (sorted.size() > TOP_K && random.nextDouble() < EXPLORE_RATE) {
            List<Breakdown> explore = sorted.stream().filter(b -> b.eaten() == 0.0).toList();
            if (!explore.isEmpty()) return explore.get(random.nextInt(explore.size()));
        }

        List<Breakdown> top = sorted.subList(0, Math.min(TOP_K, sorted.size()));
        double max = top.get(0).total();
        double[] weights = top.stream().mapToDouble(b -> Math.exp((b.total() - max) / TEMPERATURE)).toArray();
        double sum = 0;
        for (double w : weights) sum += w;

        double r = random.nextDouble() * sum;
        for (int i = 0; i < weights.length; i++) {
            r -= weights[i];
            if (r <= 0) return top.get(i);
        }
        return top.get(0);
    }
}