package com.example.dietapp.diet.controller;

import com.example.dietapp.diet.dto.UserMenuRequest;
import com.example.dietapp.diet.entity.UserMenu;
import com.example.dietapp.diet.service.UserMenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 내 메뉴 API */
@RestController
@RequestMapping("/api/user-menus")
@RequiredArgsConstructor
public class UserMenuController {

    private final UserMenuService userMenuService;

    // 같은 이름이면 수정
    @PostMapping
    public ResponseEntity<?> save(@RequestBody UserMenuRequest request) {
        try {
            return ResponseEntity.ok(userMenuService.save(request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<List<UserMenu>> list(@RequestParam("userId") String userId) {
        return ResponseEntity.ok(userMenuService.list(userId));
    }

    @DeleteMapping
    public ResponseEntity<?> delete(@RequestParam("userId") String userId,
                                    @RequestParam("foodName") String foodName) {
        userMenuService.delete(userId, foodName);
        return ResponseEntity.ok("삭제되었습니다.");
    }
}