package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DietMenu;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface DietMenuRepository extends MongoRepository<DietMenu, String> {
    // 1. 다이어트 종류로 검색
    List<DietMenu> findByDietType(String dietType);

    // 2. 술 종류로 어울리는 안주 검색
    List<DietMenu> findByPairedDrink(String pairedDrink);

    // 💡 칼로리 상한선을 기준으로 메뉴 리스트를 가져오는 쿼리
    List<DietMenu> findByCaloriesLessThanEqual(double maxCalories);
}