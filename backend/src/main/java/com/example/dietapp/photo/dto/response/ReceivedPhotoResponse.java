package com.example.dietapp.photo.dto.response;

import java.util.List;

public record ReceivedPhotoResponse(
        boolean locked,
        Long shareId,
        String imageUrl,
        String uploaderNickname,
        List<ReactionResponse> reactions
) {
    /** 받은 사진 없음 */
    public static ReceivedPhotoResponse lockedResponse() {
        return new ReceivedPhotoResponse(true, null, null, null, List.of());
    }

    /** 도착, 미열람 */
    public static ReceivedPhotoResponse lockedResponse(Long shareId) {
        return new ReceivedPhotoResponse(true, shareId, null, null, List.of());
    }
}
