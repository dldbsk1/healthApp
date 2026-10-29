package com.example.dietapp.diet.repository;

import com.example.dietapp.diet.entity.RecommendationEvent;
import com.example.dietapp.diet.entity.RecommendationEvent.Status;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface RecommendationEventRepository extends JpaRepository<RecommendationEvent, Long> {

    // 직전 추천
    Optional<RecommendationEvent> findTopByUserIdAndContextOrderByShownAtDesc(Long userId, String context);

    // 최근 추천 5개 (반복 감점)
    List<RecommendationEvent> findTop5ByUserIdAndContextOrderByShownAtDesc(Long userId, String context);

    // 기록 ↔ 최근 추천 매칭
    Optional<RecommendationEvent> findTopByUserIdAndFoodNameAndStatusInAndShownAtAfterOrderByShownAtDesc(
            Long userId, String foodName, Collection<Status> statuses, LocalDateTime after);

    // 개인화 비중(λ) 계산
    long countByUserIdAndStatusIn(Long userId, Collection<Status> statuses);
}