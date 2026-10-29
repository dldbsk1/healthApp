package com.example.dietapp.diet.repository;

import com.example.dietapp.diet.service.UserMenuService;
import com.example.dietapp.diet.entity.UserMenu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserMenuRepository extends JpaRepository<UserMenu, Long> {

    List<UserMenu> findByUserId(Long userId);

    Optional<UserMenu> findByUserIdAndFoodName(Long userId, String foodName);

    // @Transactional 안에서 호출
    void deleteByUserIdAndFoodName(Long userId, String foodName);
}
