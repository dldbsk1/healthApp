package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.DietLogDto;
import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.entity.User;
import com.example.diettotalbackend.repository.DietLogRepository;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.example.diettotalbackend.service.RecommendationFeedbackService.Personalization;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 식단/안주 추천 서비스 (내부 DB 전용)
 * - diet_menus 의 칼로리·탄단지는 모두 "1인분" 기준이고, 응답의 amount 는 항상 1.0(인분)입니다.
 * - 후보 → 칼로리 상한 필터 → 점수화(MenuScorer: 태그·영양·중복 감점·개인화) → 소프트맥스 샘플링
 * - 추천을 내려줄 때마다 추천 이력을 남기고(RecommendationFeedbackService), 이후 반응으로 취향을 학습합니다.
 */
@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    private static final double DEFAULT_RECOMMENDED_KCAL = 2000.0;
    private static final double PROTEIN_PER_KG = 1.2;           // 하루 단백질 목표 = 체중 × 1.2g
    private static final double DEFAULT_PROTEIN_TARGET = 60.0;

    private final DietMenuRepository dietMenuRepository;
    private final DietLogRepository dietLogRepository;
    private final UserIdResolver userIdResolver;
    private final MenuScorer menuScorer;
    private final RecommendationFeedbackService feedbackService;

    // 요청 한 번 동안 쓰는 "오늘 상태"
    private record Today(User user, Long uid, List<DietLog> logs, double remainingKcal, double remainingProtein) {}

    // ───────────── 오늘(새벽 4시 기준) 기록 / 남은 칼로리·단백질 ─────────────

    private Today loadToday(String userIdentifier) {
        User user = userIdResolver.findUser(userIdentifier).orElse(null);
        Long uid = user == null ? null : user.getId();
        List<DietLog> logs = uid == null ? new ArrayList<>() : findTodayLogs(uid);

        // 술도 diet_logs 에 칼로리와 함께 저장되므로, 이미 마신 술은 여기서 자동으로 반영됩니다.
        double recommended = (user != null && user.getRecommendedCalories() > 0)
                ? user.getRecommendedCalories() : DEFAULT_RECOMMENDED_KCAL;
        double consumedKcal = logs.stream().mapToDouble(DietLog::getCalories).sum();

        double proteinTarget = (user != null && user.getWeight() > 0)
                ? user.getWeight() * PROTEIN_PER_KG : DEFAULT_PROTEIN_TARGET;
        double consumedProtein = logs.stream().mapToDouble(DietLog::getProtein).sum();

        return new Today(user, uid, logs, recommended - consumedKcal, proteinTarget - consumedProtein);
    }

    private List<DietLog> findTodayLogs(Long uid) {
        LocalDateTime now = LocalDateTime.now();
        LocalDate logicalToday = now.toLocalTime().isBefore(LocalTime.of(4, 0)) ? now.toLocalDate().minusDays(1) : now.toLocalDate();
        LocalDateTime start = logicalToday.atTime(4, 0, 0);
        LocalDateTime end = logicalToday.plusDays(1).atTime(3, 59, 59, 999999999);
        return dietLogRepository.findByUserIdAndEatenAtBetween(uid, start, end);
    }

    // ───────────── 추천 진입점 ─────────────

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

        // 술은 같은 화면에서 양을 정해 나중에 기록하므로, 추천 시점에는 마실 양을 알 수 없습니다.
        // 그래서 술 칼로리를 추정해 빼지 않고, 지금 남은 칼로리 기준으로만 안주 상한을 정합니다.
        // (이미 기록한 술의 칼로리는 remainingKcal 에 자동 반영됨)
        double maxCalories = today.remainingKcal() <= 200.0 ? 300.0 : Math.min(today.remainingKcal(), 800.0);

        // 프로필이 있는 주류: 모든 메뉴를 후보로 두고, 술 프로필과 태그·묵직함을 비교해서 어울리는 안주만 남김
        //                    (밥류는 RICE 태그만 있어서 자동으로 빠짐)
        // 프로필이 없는 주류: 기존처럼 pairedDrink 직접 매핑만 사용
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

    // ───────────── 메뉴 선택 ─────────────

    /** 후보가 없거나 고를 수 없으면 null → 호출한 쪽에서 폴백 메뉴 사용 */
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
                // 프로필이 있는 주류는 "좋아하는 태그가 맞는" 안주만 후보로 인정
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

    // 칼로리 상한 이내 메뉴 (하나도 없으면 가장 가벼운 3개로 대체)
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

    // ───────────── DTO 변환 / 대체 메뉴 ─────────────

    // 메뉴 이름은 DB에 저장된 그대로 내려줍니다. (검색 결과와 동일한 이름으로 기록되도록 [분류] 접두어 없음)
    private DietLogDto convertToDto(MenuScorer.Breakdown picked, String category, Long recommendationId) {
        DietMenu menu = picked.menu();
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
                .recommendationId(recommendationId)
                .reason(picked.reason(category))
                .scoreBreakdown(picked.asMap())
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