package com.example.diettotalbackend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.Data;

@Data
@Document(collection = "diet_menus")
public class DietMenu {
    @Id
    private String id;
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    private String dietType;    // "KETO", "BALANCED", "HIGH_PROTEIN" 등
    private String pairedDrink; // "소주", "맥주", "와인" 등 (페어링용)
    private String imageUrl;
}