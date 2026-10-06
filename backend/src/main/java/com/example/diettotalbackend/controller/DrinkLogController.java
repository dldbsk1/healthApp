package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.entity.DrinkLog;
import com.example.diettotalbackend.repository.DrinkLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/drinks")
@RequiredArgsConstructor
public class DrinkLogController {

    private final DrinkLogRepository drinkLogRepository;

    @PostMapping("/log")
    public ResponseEntity<DrinkLog> saveDrinkLog(@RequestBody DrinkLog log) {
        DrinkLog savedLog = drinkLogRepository.save(log);
        return ResponseEntity.ok(savedLog);
    }
}
