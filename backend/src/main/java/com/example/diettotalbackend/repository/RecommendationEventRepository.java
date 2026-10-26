package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.RecommendationEvent;
import com.example.diettotalbackend.entity.RecommendationEvent.Status;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface RecommendationEventRepository extends JpaRepository<RecommendationEvent, Long> {

    // 같은 맥락(예: "P|소주")에서 가장 최근에 보여준 추천
    Optional<RecommendationEvent> findTopByUserIdAndContextOrderByShownAtDesc(Long userId, String context);

    // 같은 맥락에서 최근에 보여준 추천 5개 (최신순) — 최근 추천 감점에 사용
    List<RecommendationEvent> findTop5ByUserIdAndContextOrderByShownAtDesc(Long userId, String context);

    // 기록 저장 시, 최근에 추천했던 같은 이름의 메뉴를 찾을 때 사용
    Optional<RecommendationEvent> findTopByUserIdAndFoodNameAndStatusInAndShownAtAfterOrderByShownAtDesc(
            Long userId, String foodName, Collection<Status> statuses, LocalDateTime after);

    // 개인화 비중(λ) 계산용: 반응이 있었던 추천 수
    long countByUserIdAndStatusIn(Long userId, Collection<Status> statuses);
}