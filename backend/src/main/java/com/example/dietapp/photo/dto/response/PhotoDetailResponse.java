package com.example.dietapp.photo.dto.response;

import java.time.LocalDate;
import java.util.List;

public record PhotoDetailResponse(
        Long photoId,
        String imageUrl,
        String memo,
        LocalDate logDate,
        List<ReactionResponse> reactions
) {
}
