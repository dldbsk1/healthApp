package com.example.dietapp.alcohol.repository;

import com.example.dietapp.alcohol.entity.DrinkLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DrinkLogRepository extends JpaRepository<DrinkLog, Long> {
}
