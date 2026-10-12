package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.DrinkLog;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface DrinkLogRepository extends MongoRepository<DrinkLog, String> {
}
