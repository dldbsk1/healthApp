package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.FoodSearchResultDto;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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

/**
 * 식품의약품안전처 식품영양성분DB(공공데이터포털 OpenAPI) 검색 클라이언트
 * - 음식 "검색"에서만 사용합니다. (메뉴 추천에는 사용하지 않음)
 * - 인증키가 비어 있으면 아무것도 하지 않고 빈 목록을 돌려줍니다. (내부 DB 검색만 동작)
 * - 응답의 영양성분은 100g(또는 100mL) 기준이라, 1회 제공 중량(Z10500)으로 "1인분" 기준으로 환산합니다.
 */
@Service
public class MfdsFoodClient {

    private static final long CACHE_TTL_MS = 10 * 60 * 1000L;   // 같은 검색어는 10분간 재사용
    private static final int MAX_CACHE_SIZE = 300;
    private static final int NUM_OF_ROWS = 30;                    // 한 번에 받아오는 개수
    private static final int MAX_RESULTS = 15;                    // 앱에 내려주는 최대 개수
    private static final Duration TIMEOUT = Duration.ofSeconds(5);
    private static final Pattern AMOUNT_PATTERN = Pattern.compile("^\\s*([0-9][0-9,]*\\.?[0-9]*)");

    private final WebClient webClient = WebClient.builder()
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(16 * 1024 * 1024))
            .build();
    private final ObjectMapper objectMapper;

    // application.properties — 키가 없으면 식약처 검색은 꺼집니다.
    @Value("${mfds.api.key:}")
    private String apiKey;
    @Value("${mfds.api.base-url:https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo03}")
    private String baseUrl;
    // ※ 공공데이터포털 "미리보기" 주소에서 base-url 뒤에 붙는 기능 이름을 확인해 맞춰 주세요.
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
        // "닭 가슴살"처럼 띄어 쓴 검색어로 못 찾으면 붙여서 한 번 더 시도
        if (results != null && results.isEmpty() && keyword.contains(" ")) {
            results = fetch(keyword.replace(" ", ""));
        }

        if (results == null) {
            return new ArrayList<>();   // 호출 실패 → 캐시하지 않고 내부 DB 결과만 보여줌
        }

        if (cache.size() >= MAX_CACHE_SIZE) {
            cache.clear();
        }
        cache.put(cacheKey, new CacheEntry(results));
        return results;
    }

    // 성공 시 목록(빈 목록 포함), 호출 실패 시 null
    private List<FoodSearchResultDto> fetch(String keyword) {
        try {
            // 이미 인코딩된 키(%2B, %3D 포함)는 그대로, 디코딩된 키는 한 번만 인코딩
            String encodedKey = apiKey.contains("%") ? apiKey : encode(apiKey);

            // URI를 직접 만들어 넘겨서 키가 한 번 더 인코딩되지 않게 함
            String url = baseUrl + "/" + operation
                    + "?serviceKey=" + encodedKey
                    + "&pageNo=1&numOfRows=" + NUM_OF_ROWS
                    + "&type=json"
                    + "&FOOD_NM_KR=" + encode(keyword)
                    + "&DB_CLASS_NM=" + encode("품목대표");   // 대표 음식만 (외식·상용제품은 값이 비어 있는 경우가 많음)

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
                items = items.path("item");   // 일부 응답은 items.item 형태
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

            // 검색어로 시작하는 이름을 먼저, 그다음 짧은 이름 순
            String normalizedKeyword = keyword.replace(" ", "").toLowerCase();
            parsed.sort(Comparator
                    // 1회 제공량 정보가 있는 항목을 먼저 (정보 없는 항목은 100g 기준이라 실제 1인분과 다를 수 있음)
                    .comparing((FoodSearchResultDto dto) -> dto.getServingNote() != null && dto.getServingNote().contains("정보 없음"))
                    .thenComparing(dto -> !dto.getFoodName().replace(" ", "").toLowerCase().startsWith(normalizedKeyword))
                    .thenComparingInt(dto -> dto.getFoodName().length()));

            return parsed.size() > MAX_RESULTS ? new ArrayList<>(parsed.subList(0, MAX_RESULTS)) : parsed;

        } catch (Exception e) {
            // 요청 주소(인증키 포함)가 로그에 남지 않도록 예외 종류만 기록
            System.out.println("[식약처 API] 호출 실패: " + e.getClass().getSimpleName());
            return null;
        }
    }

    // 응답 한 건 → 앱에서 쓰는 형태(1인분 기준)로 변환. 열량이 없으면 건너뜀.
    private FoodSearchResultDto toDto(JsonNode item) {
        String rawName = item.path("FOOD_NM_KR").asText("");
        Double kcal100 = number(item, "AMT_NUM1");     // 에너지(kcal)
        if (rawName.isBlank() || kcal100 == null) {
            return null;
        }

        Double protein100 = number(item, "AMT_NUM3");  // 단백질(g)
        Double fat100 = number(item, "AMT_NUM4");      // 지방(g)
        Double carbs100 = number(item, "AMT_NUM6");    // 탄수화물(g)

        // 영양성분 기준량(100g 또는 100mL)과 1회 제공 중량(Z10500)으로 환산 비율 계산
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

    // "4,720.000" 같은 문자열도 숫자로. 비어 있거나 숫자가 아니면 null
    private static Double number(JsonNode item, String field) {
        String raw = item.path(field).asText("");
        if (raw.isBlank() || "null".equals(raw)) return null;
        try {
            return Double.parseDouble(raw.replace(",", "").trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    // "270.000g", "300.000mL", "100g" → 앞쪽 숫자만 추출
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