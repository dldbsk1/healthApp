package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.FoodSearchResultDto;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;

@Service
public class FoodSearchService {

    private final WebClient webClient;
    private final ObjectMapper objectMapper; // JSON 파싱을 위한 도구 추가

    @Value("${spoonacular.api.key}")
    private String apiKey;

    public FoodSearchService(WebClient.Builder webClientBuilder, ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;

        ExchangeStrategies strategies = ExchangeStrategies.builder()
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(16 * 1024 * 1024))
                .build();

        this.webClient = webClientBuilder
                .baseUrl("https://api.spoonacular.com")
                .exchangeStrategies(strategies)
                .build();
    }

    // 반환 타입을 String에서 List<FoodSearchResultDto>로 변경!
    public List<FoodSearchResultDto> searchFoodFromSpoonacular(String query) {
        try {
            // 1. 원본 데이터 문자열로 받기
            String rawJson = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/recipes/complexSearch")
                            .queryParam("query", query)
                            .queryParam("addRecipeNutrition", true)
                            .queryParam("number", 10)
                            .queryParam("apiKey", apiKey)
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            // 2. 결과 담을 리스트 준비
            List<FoodSearchResultDto> resultList = new ArrayList<>();

            // 3. JSON 트리 탐색 시작
            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode resultsArray = rootNode.path("results");

            // 4. 음식 목록(results)을 하나씩 돌면서 알맹이 빼기
            for (JsonNode node : resultsArray) {
                String foodName = node.path("title").asText();
                String imageUrl = node.path("image").asText();

                double calories = 0, carbs = 0, protein = 0, fat = 0;

                // 영양소(nutrients) 배열을 돌면서 탄/단/지/칼로리 찾기
                JsonNode nutrientsArray = node.path("nutrition").path("nutrients");
                for (JsonNode nutrient : nutrientsArray) {
                    String name = nutrient.path("name").asText();
                    double amount = nutrient.path("amount").asDouble();

                    if (name.equalsIgnoreCase("Calories")) calories = amount;
                    else if (name.equalsIgnoreCase("Carbohydrates")) carbs = amount;
                    else if (name.equalsIgnoreCase("Protein")) protein = amount;
                    else if (name.equalsIgnoreCase("Fat")) fat = amount;
                }

                // 5. DTO 포장해서 리스트에 추가
                resultList.add(FoodSearchResultDto.builder()
                        .foodName(foodName)
                        .imageUrl(imageUrl)
                        .calories(calories)
                        .carbs(carbs)
                        .protein(protein)
                        .fat(fat)
                        .build());
            }

            return resultList;

        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>(); // 에러 시 빈 리스트 반환
        }
    }
}