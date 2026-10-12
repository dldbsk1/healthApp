package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.UserMenu;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface UserMenuRepository extends MongoRepository<UserMenu, String> {

    // 해당 사용자의 메뉴만 조회
    List<UserMenu> findByUserId(String userId);

    Optional<UserMenu> findByUserIdAndFoodName(String userId, String foodName);

    void deleteByUserIdAndFoodName(String userId, String foodName);
}