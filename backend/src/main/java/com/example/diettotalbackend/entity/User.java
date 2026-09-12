package com.example.diettotalbackend.entity; // 💡 패키지명 변경됨

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.Data;

@Data
@Document(collection = "users")
public class User {
    @Id
    private String id;

    // 로그인 정보
    private String email;
    private String password;

    // 기본 정보
    private String gender;
    private int age;
    private double height;
    private double weight;

    // 다이어트 추가 정보
    private String activityLevel;
    private String goal;
    private String dietPreference;

    // 프론트엔드에서 계산해서 넘겨준 하루 권장 칼로리
    private int recommendedCalories;
}
