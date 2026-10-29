package com.example.dietapp.user.entity;

import com.example.dietapp.global.common.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

/** 응답은 UserResponse 로 변환 */
@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(exclude = "password")
public class User extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    /** BCrypt 해시 */
    @Column(nullable = false)
    private String password;

    @Column(length = 50)
    private String nickname;

    private String gender;
    private Integer age;
    private Double height;
    private Double weight;

    @Column(name = "target_weight")
    private Double targetWeight;

    @Column(name = "activity_level")
    private String activityLevel;

    private String goal;

    /** API 이름: dietPreference */
    @Column(name = "diet_type")
    private String dietType;

    @Column(name = "recommended_calories")
    private Integer recommendedCalories;

    @Builder
    public User(String email, String password, String nickname, String gender, Integer age,
                Double height, Double weight, Double targetWeight, String activityLevel,
                String goal, String dietType, Integer recommendedCalories) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
        this.gender = gender;
        this.age = age;
        this.height = height;
        this.weight = weight;
        this.targetWeight = targetWeight;
        this.activityLevel = activityLevel;
        this.goal = goal;
        this.dietType = dietType;
        this.recommendedCalories = recommendedCalories;
    }

    /** null 은 기존 값 유지 */
    public void updateProfile(String gender, Integer age, Double height, Double weight, Double targetWeight,
                              String activityLevel, String goal, String dietType, Integer recommendedCalories) {
        if (gender != null) this.gender = gender;
        if (age != null) this.age = age;
        if (height != null) this.height = height;
        if (weight != null) this.weight = weight;
        if (targetWeight != null) this.targetWeight = targetWeight;
        if (activityLevel != null) this.activityLevel = activityLevel;
        if (goal != null) this.goal = goal;
        if (dietType != null) this.dietType = dietType;
        if (recommendedCalories != null) this.recommendedCalories = recommendedCalories;
    }

    public void changeNickname(String nickname) {
        this.nickname = nickname;
    }

    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }

    public String getDietPreference() {
        return this.dietType;
    }
}
