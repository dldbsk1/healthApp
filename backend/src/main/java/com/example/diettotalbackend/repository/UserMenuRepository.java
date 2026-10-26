package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.UserMenu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserMenuRepository extends JpaRepository<UserMenu, Long> {

    // 해당 사용자의 메뉴만 조회
    List<UserMenu> findByUserId(Long userId);

    Optional<UserMenu> findByUserIdAndFoodName(Long userId, String foodName);

    // 파생 삭제 쿼리는 트랜잭션 안에서 호출해야 합니다. (UserMenuService.delete에 @Transactional)
    void deleteByUserIdAndFoodName(Long userId, String foodName);
}
