package com.example.dietapp.alcohol.repository;

import com.example.dietapp.alcohol.entity.DrinkLog;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface DrinkLogRepository extends MongoRepository<DrinkLog, String> {
}
