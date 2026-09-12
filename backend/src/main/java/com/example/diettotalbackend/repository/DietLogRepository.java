package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DietLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface DietLogRepository extends MongoRepository<DietLog, String> {

    // 🌟 StartingWith 대신 Between을 사용합니다!
    List<DietLog> findByUserIdAndEatenAtBetween(String userId, LocalDateTime start, LocalDateTime end);
}