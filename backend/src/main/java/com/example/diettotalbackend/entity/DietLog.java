package com.example.diettotalbackend.entity;

import lombok.Builder;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Builder
@Document(collection = "diet_logs") // 아까 만든 그 컬렉션 이름!
public class DietLog {
    @Id
    private String id; // MongoDB가 자동으로 만들어주는 _id
    private String userId;
    private String mealType; // breakfast, lunch, dinner, snack
    private String foodName;
    private double amount;
    private double calories;
    private double carbs;
    private double protein;
    private double fat;
    private String imageUrl;
    private LocalDateTime eatenAt; // 먹은 시간
    private LocalDateTime createdAt; // 기록한 시간
}