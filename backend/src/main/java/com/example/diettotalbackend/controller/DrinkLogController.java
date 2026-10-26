package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.dto.DrinkLogRequest;
import com.example.diettotalbackend.entity.DrinkLog;
import com.example.diettotalbackend.repository.DrinkLogRepository;
import com.example.diettotalbackend.service.UserIdResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/drinks")
@RequiredArgsConstructor
public class DrinkLogController {

    private final DrinkLogRepository drinkLogRepository;
    private final UserIdResolver userIdResolver;

    @PostMapping("/log")
    public ResponseEntity<?> saveDrinkLog(@RequestBody DrinkLogRequest request) {
        try {
            DrinkLog log = new DrinkLog();
            log.setUserId(userIdResolver.resolveId(request.getUserId()));
            log.setDrinkName(request.getDrinkName());
            log.setAmount(request.getAmount() != null ? request.getAmount() : 0.0);
            if (request.getLoggedAt() != null) {
                log.setLoggedAt(request.getLoggedAt());
            }
            return ResponseEntity.ok(drinkLogRepository.save(log));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
