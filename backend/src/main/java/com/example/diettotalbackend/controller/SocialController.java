package com.example.diettotalbackend.controller;

import com.example.diettotalbackend.entity.SocialPost;
import com.example.diettotalbackend.service.SocialService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/social")
@RequiredArgsConstructor
public class SocialController {

    private final SocialService socialService;

    // 1. 내 사진 업로드 API
    @PostMapping("/upload")
    public ResponseEntity<?> uploadPost(@RequestBody Map<String, String> request) {
        // 실제로는 MultipartFile로 이미지를 받아 S3에 올린 후 URL을 가져와야 합니다.
        String userId = request.get("userId");
        String imageUrl = request.get("imageUrl");
        return ResponseEntity.ok(socialService.saveMyPost(userId, imageUrl));
    }

    // 2. 랜덤 사진 받기 API (밤 9시 이후에만 정상 작동)
    @GetMapping("/received")
    public ResponseEntity<?> getReceivedPhoto(@RequestParam("userId") String userId) {
        try {
            return ResponseEntity.ok(socialService.getReceivedPhoto(userId));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 3. 리액션 보내기 API
    @PostMapping("/reaction")
    public ResponseEntity<?> sendReaction(@RequestBody Map<String, String> request) {
        String postId = request.get("postId");
        String emoji = request.get("emoji");
        return ResponseEntity.ok(socialService.addReaction(postId, emoji));
    }

    // 4. 내 캘린더 히스토리 조회 API
    @GetMapping("/calendar")
    public ResponseEntity<List<SocialPost>> getMyHistory(@RequestParam("userId") String userId) {
        return ResponseEntity.ok(socialService.getMyCalendarHistory(userId));
    }
}
