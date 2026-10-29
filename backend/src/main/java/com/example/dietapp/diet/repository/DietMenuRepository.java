package com.example.dietapp.diet.repository;

import com.example.dietapp.diet.entity.DietMenu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DietMenuRepository extends JpaRepository<DietMenu, Long> {
    List<DietMenu> findByDietType(String dietType);

    List<DietMenu> findByPairedDrink(String pairedDrink);

    List<DietMenu> findByCaloriesLessThanEqual(double maxCalories);

    Optional<DietMenu> findByFoodName(String foodName);
}
