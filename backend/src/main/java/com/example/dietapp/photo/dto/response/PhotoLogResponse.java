package com.example.dietapp.photo.dto.response;

import com.example.dietapp.photo.entity.PhotoLog;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record PhotoLogResponse(
        Long photoId,
        String imageUrl,
        String category,
        String memo,
        LocalDate logDate,
        LocalDateTime createdAt
) {
    public static PhotoLogResponse from(PhotoLog log) {
        return new PhotoLogResponse(
                log.getId(), log.getImageUrl(), log.getCategory(),
                log.getMemo(), log.getLogDate(), log.getCreatedAt()
        );
    }
}
