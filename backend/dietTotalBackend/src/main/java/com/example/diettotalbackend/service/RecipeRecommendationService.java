package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.DietLogDto;
import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.entity.User;
import com.example.diettotalbackend.repository.DietLogRepository;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.example.diettotalbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * 식단/안주 추천 서비스 (내부 DB 전용)
 * - diet_menus 컬렉션의 칼로리·탄단지는 모두 "1인분" 기준입니다.
 * - 응답의 amount는 항상 1.0(인분), unit은 "인분" 입니다. (인분 조절은 클라이언트 슬라이더에서 배율 적용)
 */
@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    private final Random random = new Random();

    // "다른 메뉴 추천받기"를 눌렀을 때 직전과 같은 메뉴가 연속으로 나오지 않도록 기억 (서버 재시작 시 초기화)
    private final Map<String, String> lastRecommended = new ConcurrentHashMap<>();

    private final DietMenuRepository dietMenuRepository;
    private final DietLogRepository dietLogRepository;
    private final UserRepository userRepository;

    // 해당 카테고리에 메뉴가 없을 때 대신 사용할 카테고리
    private static final Map<String, List<String>> PAIRING_FALLBACK_CATEGORIES = Map.of(
            "스파클링 와인", List.of("화이트 와인"),
            "블렌디드 위스키", List.of("싱글 몰트 위스키"),
            "버번 위스키", List.of("싱글 몰트 위스키")
    );

    // ───────────── 오늘(새벽 4시 기준) 기록 / 남은 칼로리 ─────────────

    private List<DietLog> findTodayLogs(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            return new ArrayList<>();
        }
        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();
        LocalDate logicalToday = currentTime.isBefore(LocalTime.of(4, 0)) ? now.toLocalDate().minusDays(1) : now.toLocalDate();

        LocalDateTime start = logicalToday.atTime(4, 0, 0);
        LocalDateTime end = logicalToday.plusDays(1).atTime(3, 59, 59, 999999999);

        return dietLogRepository.findByUserIdAndEatenAtBetween(userId, start, end);
    }

    private double calculateRemainingCalories(String userId, List<DietLog> todayLogs) {
        if (userId == null || userId.trim().isEmpty()) {
            return 2000.0;
        }

        User user = userRepository.findByEmail(userId).orElse(null);
        if (user == null) {
            return 2000.0;
        }

        double consumed = todayLogs.stream().mapToDouble(DietLog::getCalories).sum();

        double recommended = user.getRecommendedCalories();
        if (recommended <= 0) recommended = 2000.0;

        return recommended - consumed;
    }

    // ───────────── 추천 진입점 ─────────────

    public DietLogDto getRandomRecipeByDietType(String dietType, String userId) {
        List<DietLog> todayLogs = findTodayLogs(userId);
        double remaining = calculateRemainingCalories(userId, todayLogs);
        double maxCalories = remaining <= 200.0 ? 300.0 : Math.min(remaining, 650.0);

        String type = (dietType == null || dietType.isBlank()) ? "BALANCED" : dietType.toUpperCase();

        List<DietMenu> candidates = dietMenuRepository.findByDietType(type);
        DietMenu picked = pickMenu(candidates, maxCalories, todayLogs, userId + "|D|" + type);

        if (picked == null) {
            return createFallbackMenu();
        }
        return convertToDto(picked);
    }

    public DietLogDto getPairingRecipeByDrink(String drinkName, String userId) {
        List<DietLog> todayLogs = findTodayLogs(userId);
        double remaining = calculateRemainingCalories(userId, todayLogs);
        double maxCalories = remaining <= 200.0 ? 300.0 : Math.min(remaining, 800.0);

        String category = getGenericDrinkCategory(drinkName);

        // 요청 카테고리 → (비어 있으면) 대체 카테고리 순서로 탐색
        List<String> categories = new ArrayList<>();
        categories.add(category);
        categories.addAll(PAIRING_FALLBACK_CATEGORIES.getOrDefault(category, List.of()));

        DietMenu picked = null;
        for (String c : categories) {
            picked = pickMenu(dietMenuRepository.findByPairedDrink(c), maxCalories, todayLogs, userId + "|P|" + c);
            if (picked != null) break;
        }

        if (picked == null) {
            return createFallbackPairing();
        }
        return convertToDto(picked);
    }

    private String getGenericDrinkCategory(String drinkName) {
        if (drinkName == null) return "";
        switch (drinkName) {
            case "와인":
            case "카베르네 소비뇽": case "말벡": case "피노 누아":
                return "레드 와인";
            case "샤르도네": case "소비뇽 블랑": case "리슬링":
                return "화이트 와인";
            case "샴페인": case "프로세코": case "모스카토 다스티":
                return "스파클링 와인";
            case "글렌피딕": case "맥캘란": case "발베니":
                return "싱글 몰트 위스키";
            case "조니워커": case "발렌타인": case "시바스 리갈":
                return "블렌디드 위스키";
            case "짐빔": case "메이커스 마크": case "와일드 터키":
                return "버번 위스키";
            default:
                return drinkName;
        }
    }

    // ───────────── 메뉴 선택 ─────────────

    private DietMenu pickMenu(List<DietMenu> menus, double maxCalories, List<DietLog> todayLogs, String memoryKey) {
        if (menus == null || menus.isEmpty()) return null;

        // 1. 칼로리 상한 이내 메뉴 (하나도 없으면 가장 가벼운 3개로 대체)
        List<DietMenu> pool = menus.stream()
                .filter(m -> m.getCalories() != null && m.getCalories() <= maxCalories)
                .collect(Collectors.toList());
        if (pool.isEmpty()) {
            pool = menus.stream()
                    .filter(m -> m.getCalories() != null)
                    .sorted(Comparator.comparingDouble(DietMenu::getCalories))
                    .limit(3)
                    .collect(Collectors.toList());
            if (pool.isEmpty()) return null;
        }

        // 2. 오늘 이미 기록한 메뉴는 제외 (후보가 남아 있을 때만)
        List<DietMenu> notEatenYet = pool.stream()
                .filter(m -> m.getFoodName() != null && todayLogs.stream()
                        .noneMatch(l -> l.getFoodName() != null && l.getFoodName().contains(m.getFoodName())))
                .collect(Collectors.toList());
        if (!notEatenYet.isEmpty()) pool = notEatenYet;

        // 3. 직전에 추천한 메뉴는 제외 (후보가 2개 이상일 때만)
        String last = lastRecommended.get(memoryKey);
        if (last != null && pool.size() > 1) {
            List<DietMenu> notLast = pool.stream()
                    .filter(m -> !last.equals(m.getFoodName()))
                    .collect(Collectors.toList());
            if (!notLast.isEmpty()) pool = notLast;
        }

        DietMenu picked = pool.get(random.nextInt(pool.size()));
        lastRecommended.put(memoryKey, picked.getFoodName());
        return picked;
    }

    // ───────────── DTO 변환 / 대체 메뉴 ─────────────

    // 메뉴 이름은 DB에 저장된 그대로 내려줍니다. (검색 결과와 동일한 이름으로 기록되도록 [분류] 접두어 없음)
    private DietLogDto convertToDto(DietMenu menu) {
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName(menu.getFoodName())
                .amount(1.0)      // 1인분 기준
                .unit("인분")
                .calories(menu.getCalories())
                .carbs(menu.getCarbs())
                .protein(menu.getProtein())
                .fat(menu.getFat())
                .imageUrl(menu.getImageUrl())
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }

    // DB에 해당 카테고리 메뉴가 하나도 없을 때만 쓰이는 최후의 대체 메뉴 (1인분 기준)
    private DietLogDto createFallbackMenu() {
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName("닭가슴살 샐러드")
                .amount(1.0)
                .unit("인분")
                .calories(350.0)
                .carbs(20.0)
                .protein(40.0)
                .fat(10.0)
                .imageUrl("")
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }

    private DietLogDto createFallbackPairing() {
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName("두부 김치")
                .amount(1.0)
                .unit("인분")
                .calories(277.5)
                .carbs(22.64)
                .protein(24.24)
                .fat(12.84)
                .imageUrl("")
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }
}