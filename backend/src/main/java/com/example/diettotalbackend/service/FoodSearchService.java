package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.FoodSearchResultDto;
import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.entity.UserMenu;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.example.diettotalbackend.repository.UserMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 음식 검색 서비스 (내부 DB + 식약처 식품영양성분DB)
 * - 내부 DB(diet_menus)에서 "일부만 입력해도" 찾아줍니다. (공백/대소문자 무시)
 * - 이어서 식약처 API(MfdsFoodClient) 결과를 뒤에 붙입니다. (인증키가 없으면 내부 DB 결과만)
 * - 결과의 칼로리·탄단지는 모두 1인분 기준입니다. (인분 조절은 클라이언트 슬라이더에서 배율 적용)
 */
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

        // 1) 이 사용자가 직접 추가한 메뉴 — userId가 같은 것만 조회하므로 다른 사용자의 메뉴는 절대 섞이지 않음
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

        // 메뉴가 수백 개 수준이라 전체를 읽어 메모리에서 필터링합니다.
        // (공백을 무시한 부분 일치: "소고기미역" → "소고기 미역국")
        List<FoodSearchResultDto> internal = dietMenuRepository.findAll().stream()
                .filter(menu -> menu.getFoodName() != null && normalize(menu.getFoodName()).contains(keyword))
                .sorted(Comparator
                        .comparing((DietMenu menu) -> !normalize(menu.getFoodName()).startsWith(keyword)) // 앞부분 일치 우선
                        .thenComparing(DietMenu::getFoodName))
                .limit(MAX_INTERNAL_RESULTS)
                .map(this::toDto)
                .collect(Collectors.toList());

        // 내 메뉴 → 내부 DB → 식약처 순서로, 같은 이름은 먼저 나온 것만 남김
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

    // 기존 컨트롤러가 이 이름으로 호출하고 있어서 그대로 남겨둔 호환용 메서드입니다.
    // 컨트롤러에서 searchFood(...)로 바꿔 부르면 이 메서드는 지워도 됩니다.
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