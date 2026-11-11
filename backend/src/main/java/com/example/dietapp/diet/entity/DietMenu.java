package com.example.dietapp.diet.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.util.Arrays;
import java.util.List;

@Data
@Entity
@Table(name = "diet_menus")
public class DietMenu {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 시드 upsert 키
    @Column(nullable = false, unique = true)
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    @Column(length = 30)
    private String dietType;    // KETO / BALANCED / HIGH_PROTEIN ...
    // 술 프로필 없는 주류의 안주 매핑용
    @Column(length = 100)
    private String pairedDrink;
    @Column(length = 500)
    private String imageUrl;

    // 추천 점수용
    @Column(length = 200)
    private String tags;             // 태그 CSV (예: SPICY,SOUP,MEAT)
    private Integer heaviness;       // 1(가벼움) ~ 3(묵직함)

    public List<String> tagList() {
        return splitCsv(tags);
    }

    public static List<String> splitCsv(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toList();
    }
}