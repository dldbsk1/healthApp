package com.example.dietapp.diet.repository;

import com.example.dietapp.diet.entity.UserPreference;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserPreferenceRepository extends JpaRepository<UserPreference, Long> {
    List<UserPreference> findByUserId(Long userId);

    Optional<UserPreference> findByUserIdAndPrefKey(Long userId, String prefKey);
}