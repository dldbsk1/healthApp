package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.dto.UserMenuRequest;
import com.example.diettotalbackend.entity.UserMenu;
import com.example.diettotalbackend.service.UserMenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 사용자 개인 메뉴 API — 모든 요청은 userId 기준으로만 동작합니다. */
@RestController
@RequestMapping("/api/user-menus")
@RequiredArgsConstructor
public class UserMenuController {

    private final UserMenuService userMenuService;

    // 내 메뉴 저장(같은 이름이면 수정)
    @PostMapping
    public ResponseEntity<?> save(@RequestBody UserMenuRequest request) {
        try {
            return ResponseEntity.ok(userMenuService.save(request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 내 메뉴 목록
    @GetMapping
    public ResponseEntity<List<UserMenu>> list(@RequestParam("userId") String userId) {
        return ResponseEntity.ok(userMenuService.list(userId));
    }

    // 내 메뉴 삭제
    @DeleteMapping
    public ResponseEntity<?> delete(@RequestParam("userId") String userId,
                                    @RequestParam("foodName") String foodName) {
        userMenuService.delete(userId, foodName);
        return ResponseEntity.ok("삭제되었습니다.");
    }
}