package com.example.diettotalbackend.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * 사용자가 직접 추가한 개인 메뉴 (user_menus 컬렉션)
 * - userId가 같은 사용자의 "음식 검색"에만 보입니다. (다른 사용자에게는 보이지 않고, 메뉴 추천에도 쓰이지 않음)
 * - 칼로리·탄단지는 1인분 기준이고, 입력하지 않은 값은 null입니다.
 */
@Data
@Document(collection = "user_menus")
public class UserMenu {
    @Id
    private String id;
    private String userId;
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    private LocalDateTime createdAt = LocalDateTime.now();
}