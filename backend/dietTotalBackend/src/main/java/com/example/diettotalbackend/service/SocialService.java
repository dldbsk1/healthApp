package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.SocialPost;
import com.example.diettotalbackend.repository.SocialPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SocialService {
    private final SocialPostRepository socialPostRepository;

    // 1. 내 사진 업로드 (캘린더 저장용)
    public SocialPost saveMyPost(String userId, String imageUrl) {
        SocialPost post = new SocialPost();
        post.setUserId(userId);
        post.setImageUrl(imageUrl);
        post.setTargetDate(LocalDate.now()); // 서버의 오늘 날짜 기준 저장

        // 하루에 한 장만 올릴 수 있다면 덮어쓰기 로직 추가 가능
        return socialPostRepository.save(post);
    }

    // 2. 받은 사진 조회 (밤 9시 공개 로직)
    public SocialPost getReceivedPhoto(String userId) {
        LocalTime nowTime = LocalTime.now();
        // 9시(21:00) 이전이면 예외 발생 (프론트엔드에서 자물쇠 아이콘 유지)
        if (nowTime.isBefore(LocalTime.of(21, 0))) {
            throw new RuntimeException("밤 9시 이후에 공개됩니다.");
        }

        // 다른 유저의 오늘 날짜 게시글 중 하나를 랜덤으로 가져옴
        return socialPostRepository.findRandomPostFromOthers(userId, LocalDate.now())
                .orElseThrow(() -> new RuntimeException("오늘은 다른 유저가 올린 사진이 없습니다."));
    }

    // 3. 리액션 추가
    public SocialPost addReaction(String postId, String emoji) {
        SocialPost post = socialPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        // 기존 리액션 개수에서 +1
        post.getReactions().merge(emoji, 1, Integer::sum);
        return socialPostRepository.save(post);
    }

    // 4. 내 캘린더 기록 전체 조회
    public List<SocialPost> getMyCalendarHistory(String userId) {
        return socialPostRepository.findAllByUserId(userId);
    }
}