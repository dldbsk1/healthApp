package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DrinkLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DrinkLogRepository extends JpaRepository<DrinkLog, Long> {
}
