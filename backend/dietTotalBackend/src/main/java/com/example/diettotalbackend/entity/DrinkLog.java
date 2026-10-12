package com.example.diettotalbackend.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Document(collection = "drink_logs")
public class DrinkLog {
    @Id
    private String id;
    private String userId;
    private String drinkName; // 소주, 맥주 등
    private double amount;    // 1.5 (병/잔)
    private LocalDateTime loggedAt = LocalDateTime.now();
}
