package com.example.diettotalbackend.service;

import com.example.diettotalbackend.dto.UserMenuRequest;
import com.example.diettotalbackend.entity.UserMenu;
import com.example.diettotalbackend.repository.UserMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserMenuService {

    private final UserMenuRepository userMenuRepository;

    // 같은 이름의 메뉴가 이미 있으면 새 값으로 덮어씀 (사용자별로 구분)
    public UserMenu save(UserMenuRequest request) {
        String userId = request.getUserId();
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("사용자 정보가 없어요.");
        }
        String foodName = request.getFoodName() == null ? "" : request.getFoodName().trim();
        if (foodName.isEmpty()) {
            throw new IllegalArgumentException("메뉴 이름을 입력해 주세요.");
        }

        UserMenu menu = userMenuRepository.findByUserIdAndFoodName(userId, foodName).orElseGet(UserMenu::new);
        menu.setUserId(userId);
        menu.setFoodName(foodName);
        menu.setCalories(nonNegative(request.getCalories()));
        menu.setCarbs(nonNegative(request.getCarbs()));
        menu.setProtein(nonNegative(request.getProtein()));
        menu.setFat(nonNegative(request.getFat()));
        return userMenuRepository.save(menu);
    }

    public List<UserMenu> list(String userId) {
        return userMenuRepository.findByUserId(userId);
    }

    public void delete(String userId, String foodName) {
        userMenuRepository.deleteByUserIdAndFoodName(userId, foodName);
    }

    private Double nonNegative(Double value) {
        if (value != null && value < 0) {
            throw new IllegalArgumentException("숫자는 0 이상이어야 해요.");
        }
        return value;
    }
}