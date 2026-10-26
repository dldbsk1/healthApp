package com.example.diettotalbackend.entity;

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

    // 신메뉴 JSON을 여러 번 올려도 중복되지 않도록 이름을 유일 키로 사용
    @Column(nullable = false, unique = true)
    private String foodName;
    private Double calories;
    private Double carbs;
    private Double protein;
    private Double fat;
    @Column(length = 30)
    private String dietType;    // "KETO", "BALANCED", "HIGH_PROTEIN" 등
    // 기존 데이터(참고용). 안주 추천 점수에는 쓰지 않고, 술 프로필이 없는 술의 대체 추천에만 사용합니다.
    @Column(length = 100)
    private String pairedDrink;
    @Column(length = 500)
    private String imageUrl;

    // ───── 추천 점수화용 (diet_menu_seed.json 에서 채워짐) ─────
    @Column(length = 200)
    private String tags;             // 맛·조리형태·재료 태그 CSV. 예: "SPICY,SOUP,MEAT"
    private Integer heaviness;       // 1(가벼움) ~ 3(묵직함)

    public List<String> tagList() {
        return splitCsv(tags);
    }

    public static List<String> splitCsv(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toList();
    }
}