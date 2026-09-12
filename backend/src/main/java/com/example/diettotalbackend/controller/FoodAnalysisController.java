package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.dto.FoodSearchResultDto;
import com.example.diettotalbackend.service.FoodAnalysisService;
import com.example.diettotalbackend.service.FoodSearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/food")
@RequiredArgsConstructor
public class FoodAnalysisController {

    private final FoodAnalysisService foodAnalysisService;
    private final FoodSearchService foodSearchService;

    @PostMapping("/upload")
    public String uploadAndAnalyze(
            @RequestParam("file") MultipartFile file,
            // 💡 수정됨: Spring 서버단에서도 기본값을 0.0으로 통일하여
            // 누락 시 Python 백엔드의 FOOD_PRIORS가 정상 작동하도록 보장
            @RequestParam(value = "thickness", defaultValue = "0.0") double thickness
    ) {
        try {
            return foodAnalysisService.analyzeFoodImage(file, thickness);
        } catch (IOException e) {
            return "{\"status\": \"error\", \"message\": \"파일 처리 실패\"}";
        }
    }

    @GetMapping("/search")
    public List<FoodSearchResultDto> searchFood(@RequestParam("query") String query) {
        return foodSearchService.searchFoodFromSpoonacular(query);
    }
}