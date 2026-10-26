package com.example.diettotalbackend.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.ToString;

@Data
@Entity
@Table(name = "users")
public class User {
    // MongoDB의 _id(문자열) → MySQL의 user_id(숫자, 자동 증가)
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    // 로그인 정보
    @Column(nullable = false, unique = true)
    private String email;
    // DB에는 BCrypt 해시가 저장됩니다.
    // WRITE_ONLY: 가입/로그인 요청으로는 받지만, 어떤 응답 JSON에도 포함되지 않습니다.
    // ToString.Exclude: 로그에 객체를 찍어도 비밀번호가 나오지 않습니다.
    @Column(nullable = false)
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @ToString.Exclude
    private String password;

    // 닉네임 (선택 입력, 중복 허용) — 팀원 DB의 users.nickname 컬럼
    @Column(length = 50)
    private String nickname;

    // 기본 정보
    private String gender;
    private int age;
    private double height;
    private double weight;

    // 다이어트 추가 정보
    private String activityLevel;   // activity_level
    private String goal;            // goal
    @Column(name = "diet_type")
    private String dietPreference;  // 팀원 DB의 diet_type 컬럼과 연결

    // 프론트엔드에서 계산해서 넘겨준 하루 권장 칼로리
    private int recommendedCalories; // recommended_calories
}
