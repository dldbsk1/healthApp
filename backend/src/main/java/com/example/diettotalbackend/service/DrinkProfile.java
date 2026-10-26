package com.example.diettotalbackend.service;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * 주류 카테고리별 프로필: 어울리는 태그(prefer), 피할 태그(avoid), 어울리는 묵직함 범위.
 * 안주 추천은 이 프로필과 안주의 태그·묵직함을 비교해서 점수를 매깁니다.
 * (안주에 "어울리는 술"을 따로 적지 않습니다.) 값은 직접 정한 초기값이며 검증 전입니다.
 */
public record DrinkProfile(String category, Set<String> prefer, Set<String> avoid,
                           int minHeaviness, int maxHeaviness) {

    private static final Map<String, DrinkProfile> PROFILES = new HashMap<>();

    static {
        add("소주", set("SOUP", "SPICY", "SALTY", "SEAFOOD", "MEAT"), set("SWEET"), 1, 2);
        add("맥주", set("SALTY", "SAVORY", "FATTY", "GRILLED", "SPICY", "SMOKY"), set("SWEET"), 2, 3);
        add("하이볼", set("SALTY", "SAVORY", "FRESH", "SOUR", "GRILLED", "LIGHT"), set("SOUP"), 1, 2);
        add("막걸리", set("PAN_FRIED", "SAVORY", "SPICY", "SOUR", "TOFU", "VEGGIE"), set("SMOKY"), 1, 2);
        add("레드 와인", set("MEAT", "GRILLED", "SAVORY", "SMOKY", "FATTY"), set("SPICY", "SOUP", "SEAFOOD", "RAW"), 2, 3);
        add("화이트 와인", set("SEAFOOD", "FRESH", "LIGHT", "SOUR", "STEAMED"), set("SPICY", "SMOKY"), 1, 2);
        add("스파클링 와인", set("FRESH", "SALTY", "SEAFOOD", "LIGHT", "COLD"), set("SPICY", "SOUP"), 1, 2);
        // 싱글 몰트는 견과 같은 가벼운 안주도, 묵직한 안주도 어울려서 묵직함 범위를 전체(1~3)로 둠
        add("싱글 몰트 위스키", set("SMOKY", "SAVORY", "FATTY", "SEAFOOD", "SALTY"), set("SOUP", "SPICY"), 1, 3);
        add("블렌디드 위스키", set("SAVORY", "SALTY", "SMOKY", "GRILLED", "MEAT"), set("SOUP", "SPICY"), 2, 3);
        add("버번 위스키", set("SAVORY", "SMOKY", "FATTY", "GRILLED", "MEAT"), set("SOUP", "SPICY"), 2, 3);
    }

    /** 등록되지 않은 주류면 null (이 경우 기존 pairedDrink 직접 매핑 방식으로만 추천) */
    public static DrinkProfile of(String category) {
        return category == null ? null : PROFILES.get(category);
    }

    private static void add(String category, Set<String> prefer, Set<String> avoid,
                            int minHeaviness, int maxHeaviness) {
        PROFILES.put(category, new DrinkProfile(category, prefer, avoid, minHeaviness, maxHeaviness));
    }

    private static Set<String> set(String... values) {
        return Set.of(values);
    }
}