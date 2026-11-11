package com.example.dietapp.diet.controller;

import com.example.dietapp.diet.dto.FoodSearchResultDto;
import com.example.dietapp.diet.service.FoodAnalysisService;
import com.example.dietapp.diet.service.FoodSearchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/food")
@RequiredArgsConstructor
public class FoodAnalysisController {

    private final FoodAnalysisService foodAnalysisService;
    private final FoodSearchService foodSearchService;

    @PostMapping("/upload")
    public String uploadAndAnalyze(
            @RequestParam("file") MultipartFile file,
            // 누락 시 0.0 → AI 서버 기본값(FOOD_PRIORS) 사용
            @RequestParam(value = "thickness", defaultValue = "0.0") double thickness
    ) {
        try {
            return foodAnalysisService.analyzeFoodImage(file, thickness);
        } catch (IOException e) {
            return "{\"status\": \"error\", \"message\": \"파일 처리 실패\"}";
        } catch (RuntimeException e) {
            // AI 서버 연결 실패·시간 초과
            log.warn("[식단 AI] 분석 요청 실패: {}", e.getClass().getSimpleName());
            return "{\"status\": \"error\", \"message\": \"AI 분석 서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.\"}";
        }
    }

    @GetMapping("/search")
    public List<FoodSearchResultDto> searchFood(
            @RequestParam("query") String query,
            // 내 메뉴 포함 검색
            @RequestParam(value = "userId", required = false) String userId) {
        return foodSearchService.searchFood(query, userId);
    }
}