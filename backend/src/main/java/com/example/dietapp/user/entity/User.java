package com.example.dietapp.user.entity;

import com.example.dietapp.global.common.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String nickname;
    private String gender;
    private Integer age;
    private Double height;
    private Double weight;

    @Column(name = "target_weight")
    private Double targetWeight;

    @Column(name = "activity_level")
    private String activityLevel;

    @Column(name = "diet_type")
    private String dietType;

    @Builder
    public User(String email, String password, String nickname, String gender,
                Integer age, Double height, Double weight, Double targetWeight,
                String activityLevel, String dietType) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
        this.gender = gender;
        this.age = age;
        this.height = height;
        this.weight = weight;
        this.targetWeight = targetWeight;
        this.activityLevel = activityLevel;
        this.dietType = dietType;
    }
}
