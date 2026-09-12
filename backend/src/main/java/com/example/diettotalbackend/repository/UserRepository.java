package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.User; // 💡 entity 패키지로 import 변경
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
