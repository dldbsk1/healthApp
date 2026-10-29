package com.example.dietapp.diet.service;

import com.example.dietapp.user.service.UserIdResolver;
import com.example.dietapp.diet.dto.FoodSearchResultDto;
import com.example.dietapp.diet.entity.DietMenu;
import com.example.dietapp.diet.entity.UserMenu;
import com.example.dietapp.diet.repository.DietMenuRepository;
import com.example.dietapp.diet.repository.UserMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/** 음식 검색: 내 메뉴 → 내부 DB → 식약처 (1인분 기준, 공백·대소문자 무시) */
@Service
@RequiredArgsConstructor
public class FoodSearchService {

    private static final int MAX_MY_RESULTS = 10;
    private static final int MAX_INTERNAL_RESULTS = 10;

    private final DietMenuRepository dietMenuRepository;
    private final MfdsFoodClient mfdsFoodClient;
    private final UserMenuRepository userMenuRepository;
    private final UserIdResolver userIdResolver;

    public List<FoodSearchResultDto> searchFood(String query) {
        return searchFood(query, null);
    }

    public List<FoodSearchResultDto> searchFood(String query, String userId) {
        String keyword = normalize(query);
        if (keyword.isEmpty()) {
            return new ArrayList<>();
        }

        // 1) 내 메뉴 (본인 것만)
        List<FoodSearchResultDto> mine = new ArrayList<>();
        Long ownerId = userIdResolver.findId(userId).orElse(null);
        if (ownerId != null) {
            mine = userMenuRepository.findByUserId(ownerId).stream()
                    .filter(menu -> menu.getFoodName() != null && normalize(menu.getFoodName()).contains(keyword))
                    .sorted(Comparator
                            .comparing((UserMenu menu) -> !normalize(menu.getFoodName()).startsWith(keyword))
                            .thenComparing(UserMenu::getFoodName))
                    .limit(MAX_MY_RESULTS)
                    .map(this::toDto)
                    .collect(Collectors.toList());
        }

        // 2) 내부 DB: 전체 로드 후 메모리 필터 (수백 개 수준)
        List<FoodSearchResultDto> internal = dietMenuRepository.findAll().stream()
                .filter(menu -> menu.getFoodName() != null && normalize(menu.getFoodName()).contains(keyword))
                .sorted(Comparator
                        .comparing((DietMenu menu) -> !normalize(menu.getFoodName()).startsWith(keyword)) // 앞부분 일치 우선
                        .thenComparing(DietMenu::getFoodName))
                .limit(MAX_INTERNAL_RESULTS)
                .map(this::toDto)
                .collect(Collectors.toList());

        // 3) 식약처 추가, 이름 중복 제거
        List<FoodSearchResultDto> merged = new ArrayList<>(mine);
        Set<String> names = new HashSet<>();
        for (FoodSearchResultDto dto : mine) {
            names.add(normalize(dto.getFoodName()));
        }
        for (FoodSearchResultDto dto : internal) {
            if (names.add(normalize(dto.getFoodName()))) {
                merged.add(dto);
            }
        }
        for (FoodSearchResultDto dto : mfdsFoodClient.search(query)) {
            if (names.add(normalize(dto.getFoodName()))) {
                merged.add(dto);
            }
        }
        return merged;
    }

    // 구버전 호환용
    public List<FoodSearchResultDto> searchFoodFromSpoonacular(String query) {
        return searchFood(query);
    }

    private String normalize(String text) {
        if (text == null) return "";
        return text.replaceAll("\\s+", "").toLowerCase();
    }

    private FoodSearchResultDto toDto(UserMenu menu) {
        return FoodSearchResultDto.builder()
                .foodName(menu.getFoodName())
                .imageUrl("")
                .calories(menu.getCalories() != null ? menu.getCalories() : 0.0)
                .carbs(menu.getCarbs() != null ? menu.getCarbs() : 0.0)
                .protein(menu.getProtein() != null ? menu.getProtein() : 0.0)
                .fat(menu.getFat() != null ? menu.getFat() : 0.0)
                .source("내 메뉴")
                .build();
    }

    private FoodSearchResultDto toDto(DietMenu menu) {
        return FoodSearchResultDto.builder()
                .foodName(menu.getFoodName())
                .imageUrl(menu.getImageUrl() != null ? menu.getImageUrl() : "")
                .calories(menu.getCalories() != null ? menu.getCalories() : 0.0)
                .carbs(menu.getCarbs() != null ? menu.getCarbs() : 0.0)
                .protein(menu.getProtein() != null ? menu.getProtein() : 0.0)
                .fat(menu.getFat() != null ? menu.getFat() : 0.0)
                .build();
    }
}