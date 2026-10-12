package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.User; // 💡 entity 패키지로 import 변경
import com.example.diettotalbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.example.diettotalbackend.dto.UserUpdateRequest;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    public User registerUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("이미 가입된 이메일입니다.");
        }
        return userRepository.save(user);
    }

    public User login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));

        if (!user.getPassword().equals(password)) {
            throw new RuntimeException("비밀번호가 일치하지 않습니다.");
        }

        return user;
    }
    public void updateUserProfile(UserUpdateRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));

        user.setGender(request.getGender());
        user.setAge(request.getAge());
        user.setHeight(request.getHeight());
        user.setWeight(request.getWeight());
        user.setActivityLevel(request.getActivityLevel());
        user.setGoal(request.getGoal());
        user.setDietPreference(request.getDietPreference());

        // 새로 계산된 권장 칼로리 덮어쓰기
        user.setRecommendedCalories(request.getRecommendedCalories());

        userRepository.save(user);
    }
    public User getUserProfile(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));
    }
}