package com.example.dietapp.diet.service;

import com.example.dietapp.user.service.UserIdResolver;
import com.example.dietapp.diet.dto.DietLogDto;
import com.example.dietapp.diet.entity.DietLog;
import com.example.dietapp.global.common.LogicalDay;
import com.example.dietapp.diet.entity.DietMenu;
import com.example.dietapp.user.entity.User;
import com.example.dietapp.diet.repository.DietLogRepository;
import com.example.dietapp.diet.repository.DietMenuRepository;
import com.example.dietapp.diet.service.RecommendationFeedbackService.Personalization;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/** 식단·안주 추천: 칼로리 상한 필터 → MenuScorer 점수 → 샘플링 → 추천 이력 기록 (1인분 기준) */
@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    private static final double DEFAULT_RECOMMENDED_KCAL = 2000.0;
    private static final double PROTEIN_PER_KG = 1.2;           // g/kg
    private static final double DEFAULT_PROTEIN_TARGET = 60.0;

    private final DietMenuRepository dietMenuRepository;
    private final DietLogRepository dietLogRepository;
    private final UserIdResolver userIdResolver;
    private final MenuScorer menuScorer;
    private final RecommendationFeedbackService feedbackService;

    private record Today(User user, Long uid, List<DietLog> logs, double remainingKcal, double remainingProtein) {}

    private Today loadToday(String userIdentifier) {
        User user = userIdResolver.findUser(userIdentifier).orElse(null);
        Long uid = user == null ? null : user.getId();
        List<DietLog> logs = uid == null ? new ArrayList<>() : findTodayLogs(uid);

        // 술 칼로리도 diet_logs 에 포함
        Integer kcal = user == null ? null : user.getRecommendedCalories();
        double recommended = (kcal != null && kcal > 0) ? kcal : DEFAULT_RECOMMENDED_KCAL;
        double consumedKcal = logs.stream().mapToDouble(DietLog::getCalories).sum();

        Double weight = user == null ? null : user.getWeight();
        double proteinTarget = (weight != null && weight > 0) ? weight * PROTEIN_PER_KG : DEFAULT_PROTEIN_TARGET;
        double consumedProtein = logs.stream().mapToDouble(DietLog::getProtein).sum();

        return new Today(user, uid, logs, recommended - consumedKcal, proteinTarget - consumedProtein);
    }

    private List<DietLog> findTodayLogs(Long uid) {
        LocalDate today = LogicalDay.today();
        return dietLogRepository.findByUserIdAndEatenAtBetween(uid, LogicalDay.start(today), LogicalDay.end(today));
    }

    public DietLogDto getRandomRecipeByDietType(String dietType, String userId) {
        Today today = loadToday(userId);
        double maxCalories = today.remainingKcal() <= 200.0 ? 300.0 : Math.min(today.remainingKcal(), 650.0);

        String type = (dietType == null || dietType.isBlank()) ? "BALANCED" : dietType.toUpperCase();

        DietLogDto dto = recommend(today, "D|" + type, dietMenuRepository.findByDietType(type), maxCalories, null, null);
        return dto != null ? dto : createFallbackMenu();
    }

    public DietLogDto getPairingRecipeByDrink(String drinkName, String userId) {
        Today today = loadToday(userId);

        String category = getGenericDrinkCategory(drinkName);
        DrinkProfile profile = DrinkProfile.of(category);

        // 마실 양 미정 → 술 칼로리 미차감, 남은 칼로리 기준
        double maxCalories = today.remainingKcal() <= 200.0 ? 300.0 : Math.min(today.remainingKcal(), 800.0);

        // 프로필 있음: 전체 메뉴 태그 매칭 / 없음: pairedDrink 매핑
        List<DietMenu> candidates = profile != null
                ? dietMenuRepository.findAll()
                : dietMenuRepository.findByPairedDrink(category);

        DietLogDto dto = recommend(today, "P|" + category, candidates, maxCalories, category, profile);
        return dto != null ? dto : createFallbackPairing();
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

    /** 후보 없으면 null → 폴백 */
    private DietLogDto recommend(Today today, String context, List<DietMenu> menus, double maxCalories,
                                 String category, DrinkProfile profile) {
        List<DietMenu> pool = withinCalories(menus, maxCalories);
        if (pool.isEmpty()) return null;

        Personalization personalization = today.uid() == null ? Personalization.NONE : feedbackService.load(today.uid());
        List<String> recent = today.uid() == null ? List.of() : feedbackService.recentShownFoods(today.uid(), context);
        String dietPreference = today.user() == null ? null : today.user().getDietPreference();

        MenuScorer.Context sc = new MenuScorer.Context(category, profile, maxCalories, today.logs(),
                dietPreference, today.remainingProtein(), recent, personalization);

        List<MenuScorer.Breakdown> scored = pool.stream()
                .map(m -> menuScorer.score(m, sc))
                .filter(b -> profile == null || b.fits())
                .collect(Collectors.toList());

        MenuScorer.Breakdown picked = menuScorer.select(scored);
        if (picked == null) return null;

        Long recommendationId = null;
        if (today.uid() != null) {
            recommendationId = feedbackService.recordShown(today.uid(), context, picked.menu().getFoodName()).getId();
        }
        return convertToDto(picked, category, recommendationId);
    }

    // 상한 내 메뉴, 없으면 가장 가벼운 3개
    private List<DietMenu> withinCalories(List<DietMenu> menus, double maxCalories) {
        if (menus == null || menus.isEmpty()) return new ArrayList<>();
        List<DietMenu> pool = menus.stream()
                .filter(m -> m.getCalories() != null && m.getCalories() <= maxCalories)
                .collect(Collectors.toList());
        if (pool.isEmpty()) {
            pool = menus.stream()
                    .filter(m -> m.getCalories() != null)
                    .sorted(Comparator.comparingDouble(DietMenu::getCalories))
                    .limit(3)
                    .collect(Collectors.toList());
        }
        return pool;
    }

    // 검색 결과와 같은 이름 유지
    private DietLogDto convertToDto(MenuScorer.Breakdown picked, String category, Long recommendationId) {
        DietMenu menu = picked.menu();
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName(menu.getFoodName())
                .amount(1.0)      // 인분
                .unit("인분")
                .calories(menu.getCalories())
                .carbs(menu.getCarbs())
                .protein(menu.getProtein())
                .fat(menu.getFat())
                .imageUrl(menu.getImageUrl())
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .recommendationId(recommendationId)
                .reason(picked.reason(category))
                .scoreBreakdown(picked.asMap())
                .build();
    }

    // DB에 후보 없을 때 폴백
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