package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DietLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface DietLogRepository extends JpaRepository<DietLog, Long> {

    List<DietLog> findByUserIdAndEatenAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}
