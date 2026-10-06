package com.example.diettotalbackend.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@Data
@Document(collection = "social_posts")
public class SocialPost {
    @Id
    private String id;
    private String userId; // 글 작성자
    private String imageUrl; // S3 등에 업로드된 이미지 주소
    private LocalDate targetDate; // "2026-06-15" (등록된 날짜)

    // 리액션 종류별 카운트 (예: {"❤️": 3, "🔥": 1})
    private Map<String, Integer> reactions = new HashMap<>();
}
