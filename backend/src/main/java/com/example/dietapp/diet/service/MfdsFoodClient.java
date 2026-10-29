package com.example.dietapp.diet.service;

import com.example.dietapp.diet.dto.FoodSearchResultDto;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** 식약처 식품영양성분DB 검색 (검색 전용, 키 없으면 빈 목록, 100g → 1인분 환산) */
@Service
public class MfdsFoodClient {

    private static final long CACHE_TTL_MS = 10 * 60 * 1000L;   // 10분
    private static final int MAX_CACHE_SIZE = 300;
    private static final int NUM_OF_ROWS = 30;                    // 요청 개수
    private static final int MAX_RESULTS = 15;                    // 응답 최대 개수
    private static final Duration TIMEOUT = Duration.ofSeconds(5);
    private static final Pattern AMOUNT_PATTERN = Pattern.compile("^\\s*([0-9][0-9,]*\\.?[0-9]*)");

    private final WebClient webClient = WebClient.builder()
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(16 * 1024 * 1024))
            .build();
    private final ObjectMapper objectMapper;

    @Value("${mfds.api.key:}")
    private String apiKey;
    @Value("${mfds.api.base-url:https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo03}")
    private String baseUrl;
    // 공공데이터포털 기능명과 일치해야 함
    @Value("${mfds.api.operation:getFoodNtrCpntDbInq03}")
    private String operation;

    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public MfdsFoodClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public List<FoodSearchResultDto> search(String query) {
        if (apiKey == null || apiKey.isBlank() || query == null || query.isBlank()) {
            return new ArrayList<>();
        }

        String keyword = query.trim();
        String cacheKey = keyword.toLowerCase();

        CacheEntry cached = cache.get(cacheKey);
        if (cached != null && System.currentTimeMillis() - cached.savedAt < CACHE_TTL_MS) {
            return cached.results;
        }

        List<FoodSearchResultDto> results = fetch(keyword);
        // 띄어쓰기 제거 후 재시도
        if (results != null && results.isEmpty() && keyword.contains(" ")) {
            results = fetch(keyword.replace(" ", ""));
        }

        if (results == null) {
            return new ArrayList<>();   // 실패 → 캐시 안 함
        }

        if (cache.size() >= MAX_CACHE_SIZE) {
            cache.clear();
        }
        cache.put(cacheKey, new CacheEntry(results));
        return results;
    }

    // 실패 시 null
    private List<FoodSearchResultDto> fetch(String keyword) {
        try {
            // 인코딩된 키는 그대로
            String encodedKey = apiKey.contains("%") ? apiKey : encode(apiKey);

            // 키 이중 인코딩 방지
            String url = baseUrl + "/" + operation
                    + "?serviceKey=" + encodedKey
                    + "&pageNo=1&numOfRows=" + NUM_OF_ROWS
                    + "&type=json"
                    + "&FOOD_NM_KR=" + encode(keyword)
                    + "&DB_CLASS_NM=" + encode("품목대표");   // 대표 음식만

            String body = webClient.get()
                    .uri(URI.create(url))
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(TIMEOUT);

            if (body == null || body.isBlank()) {
                return null;
            }

            JsonNode root = objectMapper.readTree(body);
            String resultCode = root.path("header").path("resultCode").asText("");
            if (!"00".equals(resultCode)) {
                System.out.println("[식약처 API] 오류 응답: " + root.path("header").path("resultMsg").asText(""));
                return null;
            }

            JsonNode items = root.path("body").path("items");
            if (items.isObject() && items.has("item")) {
                items = items.path("item");   // items.item 형태 대응
            }

            List<FoodSearchResultDto> parsed = new ArrayList<>();
            Set<String> seen = new HashSet<>();
            if (items.isArray()) {
                for (JsonNode item : items) {
                    FoodSearchResultDto dto = toDto(item);
                    if (dto != null && seen.add(dto.getFoodName())) {
                        parsed.add(dto);
                    }
                }
            }

            // 정렬: 1회 제공량 있음 → 검색어로 시작 → 짧은 이름
            String normalizedKeyword = keyword.replace(" ", "").toLowerCase();
            parsed.sort(Comparator
                    .comparing((FoodSearchResultDto dto) -> dto.getServingNote() != null && dto.getServingNote().contains("정보 없음"))
                    .thenComparing(dto -> !dto.getFoodName().replace(" ", "").toLowerCase().startsWith(normalizedKeyword))
                    .thenComparingInt(dto -> dto.getFoodName().length()));

            return parsed.size() > MAX_RESULTS ? new ArrayList<>(parsed.subList(0, MAX_RESULTS)) : parsed;

        } catch (Exception e) {
            // 인증키 노출 방지: 예외 종류만 로그
            System.out.println("[식약처 API] 호출 실패: " + e.getClass().getSimpleName());
            return null;
        }
    }

    // 1인분 기준 변환, 열량 없으면 skip
    private FoodSearchResultDto toDto(JsonNode item) {
        String rawName = item.path("FOOD_NM_KR").asText("");
        Double kcal100 = number(item, "AMT_NUM1");     // kcal
        if (rawName.isBlank() || kcal100 == null) {
            return null;
        }

        Double protein100 = number(item, "AMT_NUM3");  // 단백질
        Double fat100 = number(item, "AMT_NUM4");      // 지방
        Double carbs100 = number(item, "AMT_NUM6");    // 탄수화물

        // 1회 제공 중량(Z10500) / 기준량(100g·mL)
        Double basisAmount = amount(item.path("SERVING_SIZE").asText(""));
        double basis = (basisAmount != null && basisAmount > 0) ? basisAmount : 100.0;
        String unit = item.path("SERVING_SIZE").asText("").toLowerCase().contains("ml") ? "mL" : "g";

        Double servingAmount = amount(item.path("Z10500").asText(""));
        double factor;
        String note;
        if (servingAmount != null && servingAmount > 0) {
            factor = servingAmount / basis;
            note = "1인분 = " + format(servingAmount) + unit + " (식약처 기준)";
        } else {
            factor = 1.0;
            note = "1인분 = " + format(basis) + unit + " (1회 제공량 정보 없음)";
        }

        if (protein100 == null || fat100 == null || carbs100 == null) {
            note += " · 일부 영양 정보 없음";
        }

        return FoodSearchResultDto.builder()
                .foodName(rawName.replace("_", " · "))
                .imageUrl("")
                .calories(round(kcal100 * factor))
                .carbs(round(orZero(carbs100) * factor))
                .protein(round(orZero(protein100) * factor))
                .fat(round(orZero(fat100) * factor))
                .source("식약처")
                .servingNote(note)
                .build();
    }

    // "4,720.000" → 4720.0
    private static Double number(JsonNode item, String field) {
        String raw = item.path(field).asText("");
        if (raw.isBlank() || "null".equals(raw)) return null;
        try {
            return Double.parseDouble(raw.replace(",", "").trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    // "270.000g" → 270.0
    private static Double amount(String text) {
        if (text == null) return null;
        Matcher matcher = AMOUNT_PATTERN.matcher(text);
        if (!matcher.find()) return null;
        try {
            return Double.parseDouble(matcher.group(1).replace(",", ""));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String encode(String text) {
        return URLEncoder.encode(text, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private static double orZero(Double value) {
        return value == null ? 0.0 : value;
    }

    private static double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private static String format(double value) {
        return value == Math.floor(value) ? String.valueOf((long) value) : String.valueOf(round(value));
    }

    private static class CacheEntry {
        final List<FoodSearchResultDto> results;
        final long savedAt = System.currentTimeMillis();

        CacheEntry(List<FoodSearchResultDto> results) {
            this.results = results;
        }
    }
}