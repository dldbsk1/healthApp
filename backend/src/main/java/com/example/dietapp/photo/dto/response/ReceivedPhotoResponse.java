package com.example.dietapp.photo.dto.response;

import java.util.List;

/**
 * SNS탭 "받은 사진" 카드.
 * locked=true 면 밤 9시가 아직 안 지난 상태 — 이때는 imageUrl/reactions 를 내려주지 않는다.
 */
public record ReceivedPhotoResponse(
        boolean locked,
        Long shareId,
        String imageUrl,
        String uploaderNickname,
        List<ReactionResponse> reactions
) {
    public static ReceivedPhotoResponse lockedResponse() {
        return new ReceivedPhotoResponse(true, null, null, null, List.of());
    }
}