package com.example.diettotalbackend.repository;

import com.example.diettotalbackend.entity.SocialPost;
import org.springframework.data.mongodb.repository.Aggregation;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface SocialPostRepository extends MongoRepository<SocialPost, String> {
    // 1. 내 특정 날짜 게시글 찾기
    Optional<SocialPost> findByUserIdAndTargetDate(String userId, LocalDate targetDate);

    // 2. 캘린더에 뿌려줄 내 모든 게시글 찾기
    List<SocialPost> findAllByUserId(String userId);

    // 3. 랜덤 사진 뽑기 (MongoDB Aggregation 사용: 나를 제외한 오늘자 게시글 중 랜덤 1개)
    @Aggregation(pipeline = {
            "{ $match: { targetDate: ?1, userId: { $ne: ?0 } } }",
            "{ $sample: { size: 1 } }"
    })
    Optional<SocialPost> findRandomPostFromOthers(String userId, LocalDate today);
}
