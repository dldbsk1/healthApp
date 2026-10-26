package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.dto.DietLogDto;
import com.example.diettotalbackend.service.RecipeRecommendationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/recommendation")
@RequiredArgsConstructor
public class RecipeRecommendationController {

    private final RecipeRecommendationService recommendationService;

    @GetMapping("/random")
    public ResponseEntity<DietLogDto> getRandomRecommendation(@RequestParam String dietType, @RequestParam String userId) {
        DietLogDto recommendedLog = recommendationService.getRandomRecipeByDietType(dietType, userId);
        return ResponseEntity.ok(recommendedLog);
    }

    @GetMapping("/pairing")
    public ResponseEntity<DietLogDto> getDrinkPairing(@RequestParam String drink, @RequestParam String userId) {
        DietLogDto pairingLog = recommendationService.getPairingRecipeByDrink(drink, userId);
        return ResponseEntity.ok(pairingLog);
    }
}