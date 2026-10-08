package com.example.dietapp.photo.dto.response;

import java.util.List;

public record ReceivedPhotoResponse(
        boolean locked,
        Long shareId,
        String imageUrl,
        String uploaderNickname,
        List<ReactionResponse> reactions
) {
    /** 오늘 받은 사진이 없을 때 */
    public static ReceivedPhotoResponse lockedResponse() {
        return new ReceivedPhotoResponse(true, null, null, null, List.of());
    }

    /** 사진은 도착했지만 아직 열어보지 않았을 때 (shareId만 내려줌) */
    public static ReceivedPhotoResponse lockedResponse(Long shareId) {
        return new ReceivedPhotoResponse(true, shareId, null, null, List.of());
    }
}
