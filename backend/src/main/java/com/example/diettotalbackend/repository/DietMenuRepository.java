package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DietMenu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DietMenuRepository extends JpaRepository<DietMenu, Long> {
    // 1. 다이어트 종류로 검색
    List<DietMenu> findByDietType(String dietType);

    // 2. 술 종류로 어울리는 안주 검색
    List<DietMenu> findByPairedDrink(String pairedDrink);

    // 💡 칼로리 상한선을 기준으로 메뉴 리스트를 가져오는 쿼리
    List<DietMenu> findByCaloriesLessThanEqual(double maxCalories);

    // 신메뉴 JSON 업로드(upsert)에서 이름으로 기존 메뉴를 찾을 때 사용
    Optional<DietMenu> findByFoodName(String foodName);
}
