package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.DietLogDto;
import com.example.diettotalbackend.entity.DietLog;
import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.entity.User;
import com.example.diettotalbackend.repository.DietLogRepository;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.example.diettotalbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecipeRecommendationService {

    @Value("${spoonacular.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final Random random = new Random();

    private final DietMenuRepository dietMenuRepository;
    private final DietLogRepository dietLogRepository;
    private final UserRepository userRepository;

    private double calculateRemainingCalories(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            return 2000.0;
        }

        User user = userRepository.findByEmail(userId).orElse(null);
        if (user == null) {
            return 2000.0;
        }

        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();
        LocalDate logicalToday = currentTime.isBefore(LocalTime.of(4, 0)) ? now.toLocalDate().minusDays(1) : now.toLocalDate();

        LocalDateTime start = logicalToday.atTime(4, 0, 0);
        LocalDateTime end = logicalToday.plusDays(1).atTime(3, 59, 59, 999999999);

        List<DietLog> todayLogs = dietLogRepository.findByUserIdAndEatenAtBetween(userId, start, end);
        double consumed = todayLogs.stream().mapToDouble(DietLog::getCalories).sum();

        double recommended = user.getRecommendedCalories();
        if (recommended <= 0) recommended = 2000.0;

        return recommended - consumed;
    }

    public DietLogDto getRandomRecipeByDietType(String dietType, String userId) {
        double remaining = calculateRemainingCalories(userId);

        boolean useApi = remaining > 200.0 ? random.nextBoolean() : false;
        double maxCalories = remaining <= 200.0 ? 300.0 : Math.min(remaining, 650.0);

        if (useApi) {
            try {
                return fetchFromSpoonacularApi(dietType, maxCalories);
            } catch (Exception e) {
                System.out.println("⚠️ API 에러 발생, 내부 DB 식단으로 대체합니다: " + e.getMessage());
                DietLogDto dbResult = fetchFromDatabaseMenu(dietType, maxCalories);
                return dbResult != null ? dbResult : createFallbackMenu(dietType);
            }
        } else {
            DietLogDto dbResult = fetchFromDatabaseMenu(dietType, maxCalories);
            if (dbResult != null) {
                return dbResult;
            }
            return fetchFromSpoonacularApi(dietType, maxCalories);
        }
    }

    public DietLogDto getPairingRecipeByDrink(String drinkName, String userId) {
        double remaining = calculateRemainingCalories(userId);

        boolean useApi = remaining > 200.0 ? random.nextBoolean() : false;
        double maxCalories = remaining <= 200.0 ? 300.0 : Math.min(remaining, 800.0);
        String categoryForDb = getGenericDrinkCategory(drinkName);

        if (useApi) {
            try {
                return fetchPairingFromSpoonacularApi(drinkName, maxCalories);
            } catch (Exception e) {
                System.out.println("⚠️ API 에러 발생, 내부 DB 안주로 대체합니다: " + e.getMessage());
                DietLogDto dbResult = fetchFromDatabasePairing(categoryForDb, maxCalories);
                return dbResult != null ? dbResult : createFallbackPairing(drinkName);
            }
        } else {
            DietLogDto dbResult = fetchFromDatabasePairing(categoryForDb, maxCalories);
            if (dbResult != null) {
                return dbResult;
            }
            return fetchPairingFromSpoonacularApi(drinkName, maxCalories);
        }
    }

    private String getGenericDrinkCategory(String drinkName) {
        switch (drinkName) {
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

    private DietLogDto fetchFromDatabaseMenu(String dietType, double maxCalories) {
        List<DietMenu> internalMenus = dietMenuRepository.findByDietType(dietType.toUpperCase());
        return filterAndGetRandomDbMenu(internalMenus, maxCalories, dietType, null);
    }

    private DietLogDto fetchFromDatabasePairing(String categoryForDb, double maxCalories) {
        List<DietMenu> internalPairings = dietMenuRepository.findByPairedDrink(categoryForDb);
        return filterAndGetRandomDbMenu(internalPairings, maxCalories, null, categoryForDb);
    }

    private DietLogDto filterAndGetRandomDbMenu(List<DietMenu> menus, double maxCalories, String dietType, String drinkName) {
        if (menus == null || menus.isEmpty()) return null;

        List<DietMenu> filteredMenus = menus.stream()
                .filter(menu -> menu.getCalories() <= maxCalories)
                .collect(Collectors.toList());

        if (filteredMenus.isEmpty()) return null;

        DietMenu randomMenu = filteredMenus.get(random.nextInt(filteredMenus.size()));
        return convertToDto(randomMenu, dietType, drinkName);
    }

    private DietLogDto convertToDto(DietMenu menu, String dietType, String drinkName) {
        String finalFoodName = menu.getFoodName();

        if (dietType != null) {
            finalFoodName = "[" + getKoreanDietType(dietType) + "] " + finalFoodName;
        } else if (drinkName != null) {
            finalFoodName = "[" + drinkName + " 찰떡궁합] " + finalFoodName;
        }

        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName(finalFoodName)
                .amount(200.0)
                .calories(menu.getCalories())
                .carbs(menu.getCarbs())
                .protein(menu.getProtein())
                .fat(menu.getFat())
                .imageUrl(menu.getImageUrl())
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }

    private DietLogDto fetchFromSpoonacularApi(String dietType, double maxCalories) {
        String baseUrl = "https://api.spoonacular.com/recipes/complexSearch";
        String[] familiarGenres = {"KOREAN", "JAPANESE", "CHINESE", "WESTERN", "SALAD"};
        String selectedGenre = familiarGenres[random.nextInt(familiarGenres.length)];

        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl)
                .queryParam("apiKey", apiKey)
                .queryParam("number", 1)
                .queryParam("sort", "random")
                .queryParam("addRecipeNutrition", "true")
                .queryParam("minCalories", 150)
                .queryParam("maxCalories", (int) maxCalories);

        if (maxCalories > 300.0) {
            switch (selectedGenre) {
                case "KOREAN": builder.queryParam("cuisine", "Korean"); break;
                case "JAPANESE": builder.queryParam("cuisine", "Japanese"); break;
                case "CHINESE": builder.queryParam("cuisine", "Chinese"); break;
                case "WESTERN": builder.queryParam("cuisine", "Italian"); break;
                case "SALAD": builder.queryParam("type", "salad"); break;
            }
            switch (dietType.toUpperCase()) {
                case "BALANCED": builder.queryParam("minProtein", 15); break;
                case "HIGH_PROTEIN": builder.queryParam("minProtein", 40); break;
                case "KETO": builder.queryParam("diet", "ketogenic"); break;
                case "MEDITERRANEAN": builder.queryParam("diet", "pescetarian"); break;
                case "VEGAN": builder.queryParam("diet", "vegan"); break;
                default: builder.queryParam("minProtein", 10);
            }
        } else {
            builder.queryParam("type", "salad,soup");
        }

        try {
            String responseJson = restTemplate.getForObject(builder.toUriString(), String.class);
            JsonNode root = objectMapper.readTree(responseJson);
            JsonNode resultNode = root.path("results").get(0);

            if (resultNode == null || resultNode.isMissingNode()) {
                throw new RuntimeException("조건에 맞는 레시피를 찾을 수 없습니다.");
            }

            String originalTitle = resultNode.path("title").asText();
            String image = resultNode.path("image").asText();
            JsonNode nutrients = resultNode.path("nutrition").path("nutrients");

            double calories = 0, carbs = 0, protein = 0, fat = 0;
            double amount = resultNode.path("nutrition").path("weightPerServing").path("amount").asDouble(200.0);

            for (JsonNode nutrient : nutrients) {
                String name = nutrient.path("name").asText();
                double value = nutrient.path("amount").asDouble(0.0);
                switch (name) {
                    case "Calories": calories = value; break;
                    case "Carbohydrates": carbs = value; break;
                    case "Protein": protein = value; break;
                    case "Fat": fat = value; break;
                }
            }

            String translatedTitle = translateEnglishToKorean(originalTitle);
            String displayDietType = getKoreanDietType(dietType);

            return DietLogDto.builder()
                    .userId("")
                    .mealType("")
                    .foodName("[" + displayDietType + "] " + translatedTitle)
                    .amount(amount)
                    .calories(calories)
                    .carbs(carbs)
                    .protein(protein)
                    .fat(fat)
                    .imageUrl(image)
                    .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .build();

        } catch (Exception e) {
            System.out.println("❌ 식단 추천 에러: " + e.getMessage());
            return createFallbackMenu(dietType);
        }
    }

    private DietLogDto fetchPairingFromSpoonacularApi(String drinkName, double maxCalories) {
        String baseUrl = "https://api.spoonacular.com/recipes/complexSearch";

        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl)
                .queryParam("apiKey", apiKey)
                .queryParam("number", 1)
                .queryParam("sort", "random")
                .queryParam("addRecipeNutrition", "true")
                .queryParam("minCalories", 150)
                .queryParam("maxCalories", (int) maxCalories);

        if (maxCalories > 300.0) {
            switch (drinkName) {
// 💡 단일 키워드 하나만 무작위로 선택하도록 배열(String[])로 원상 복구
                case "소주":
                    String[] sojuQueries = {"pork", "spicy", "stew", "seafood", "noodle"};
                    builder.queryParam("query", sojuQueries[random.nextInt(sojuQueries.length)]);
                    break;
                case "맥주":
                    String[] beerQueries = {"fried", "cheese", "potato", "sausage", "chicken"};
                    builder.queryParam("query", beerQueries[random.nextInt(beerQueries.length)]);
                    break;
                case "막걸리":
                    String[] makgeolliQueries = {"pancake", "pork", "spicy", "kimchi", "tofu"};
                    builder.queryParam("cuisine", "Asian").queryParam("query", makgeolliQueries[random.nextInt(makgeolliQueries.length)]);
                    break;
                case "하이볼":
                    String[] highballQueries = {"chicken", "skewer", "fried", "snack"};
                    builder.queryParam("query", highballQueries[random.nextInt(highballQueries.length)]);
                    break;
                case "글렌피딕": case "맥캘란": case "발베니": // 싱글 몰트
                    String[] singleMaltQueries = {"salmon", "nuts", "chocolate", "steak"};
                    builder.queryParam("query", singleMaltQueries[random.nextInt(singleMaltQueries.length)]);
                    break;
                case "조니워커": case "발렌타인": case "시바스 리갈": // 블렌디드
                    String[] blendedQueries = {"cheese", "fruit", "prosciutto"};
                    builder.queryParam("query", blendedQueries[random.nextInt(blendedQueries.length)]);
                    break;
                case "짐빔": case "메이커스 마크": case "와일드 터키": // 버번
                    String[] bourbonQueries = {"bbq", "steak", "bacon", "burger"};
                    builder.queryParam("query", bourbonQueries[random.nextInt(bourbonQueries.length)]);
                    break;
                case "카베르네 소비뇽": case "말벡": case "피노 누아": case "와인": // 레드 와인
                    String[] redWineQueries = {"beef", "cheese", "mushroom", "steak"};
                    builder.queryParam("query", redWineQueries[random.nextInt(redWineQueries.length)]);
                    break;
                case "샤르도네": case "소비뇽 블랑": case "리슬링": // 화이트 와인
                    String[] whiteWineQueries = {"seafood", "chicken", "salad", "pasta"};
                    builder.queryParam("query", whiteWineQueries[random.nextInt(whiteWineQueries.length)]);
                    break;
                case "샴페인": case "프로세코": case "모스카토 다스티": // 스파클링 와인
                    String[] sparklingQueries = {"cheese", "fruit", "cake", "tart"};
                    builder.queryParam("query", sparklingQueries[random.nextInt(sparklingQueries.length)]);
                    break;
                default:
                    builder.queryParam("type", "snack,main course");
            }
        } else {
            builder.queryParam("type", "salad,snack");
            builder.queryParam("query", "vegetable");
        }

        try {
            String responseJson = restTemplate.getForObject(builder.toUriString(), String.class);
            JsonNode root = objectMapper.readTree(responseJson);
            JsonNode resultNode = root.path("results").get(0);

            if (resultNode == null || resultNode.isMissingNode()) {
                throw new RuntimeException("조건에 맞는 안주를 찾을 수 없습니다.");
            }

            String originalTitle = resultNode.path("title").asText();
            String image = resultNode.path("image").asText();
            JsonNode nutrients = resultNode.path("nutrition").path("nutrients");

            double calories = 0, carbs = 0, protein = 0, fat = 0;
            double amount = resultNode.path("nutrition").path("weightPerServing").path("amount").asDouble(200.0);

            for (JsonNode nutrient : nutrients) {
                String name = nutrient.path("name").asText();
                double value = nutrient.path("amount").asDouble(0.0);
                switch (name) {
                    case "Calories": calories = value; break;
                    case "Carbohydrates": carbs = value; break;
                    case "Protein": protein = value; break;
                    case "Fat": fat = value; break;
                }
            }

            String translatedTitle = translateEnglishToKorean(originalTitle);

            return DietLogDto.builder()
                    .userId("")
                    .mealType("")
                    .foodName("[" + drinkName + " 찰떡궁합] " + translatedTitle)
                    .amount(amount)
                    .calories(calories)
                    .carbs(carbs)
                    .protein(protein)
                    .fat(fat)
                    .imageUrl(image)
                    .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .build();

        } catch (Exception e) {
            System.out.println("❌ 안주 추천 에러: " + e.getMessage());
            return createFallbackPairing(drinkName);
        }
    }

    private String translateEnglishToKorean(String text) {
        try {
            String url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ko&dt=t&q=" + text;
            URI uri = new URI(url.replace(" ", "%20"));

            String response = restTemplate.getForObject(uri, String.class);
            JsonNode root = objectMapper.readTree(response);

            return root.get(0).get(0).get(0).asText();

        } catch (Exception e) {
            System.out.println("❌ 번역 실패, 원본 영어로 반환: " + e.getMessage());
            return text;
        }
    }

    private String getKoreanDietType(String type) {
        switch (type.toUpperCase()) {
            case "BALANCED": return "일반 균형식";
            case "HIGH_PROTEIN": return "고단백";
            case "KETO": return "키토제닉";
            case "MEDITERRANEAN": return "지중해식";
            case "VEGAN": return "비건채식";
            default: return "추천";
        }
    }

    private DietLogDto createFallbackMenu(String dietType) {
        String displayDietType = getKoreanDietType(dietType);
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName("[" + displayDietType + "] 스페셜 닭가슴살 보울 (대체 메뉴)")
                .amount(250.0)
                .calories(350.0)
                .carbs(20.0)
                .protein(40.0)
                .fat(10.0)
                .imageUrl("https://spoonacular.com/recipeImages/592479-312x231.jpg")
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }

    private DietLogDto createFallbackPairing(String drinkName) {
        return DietLogDto.builder()
                .userId("")
                .mealType("")
                .foodName("[" + drinkName + "] 매콤달콤 떡볶이와 튀김")
                .amount(250.0)
                .calories(450.0)
                .carbs(60.0)
                .protein(12.0)
                .fat(15.0)
                .imageUrl("https://spoonacular.com/recipeImages/716426-312x231.jpg")
                .eatenAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                .build();
    }
}