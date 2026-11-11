package com.example.dietapp.photo.dto.response;

import com.example.dietapp.photo.entity.PhotoReaction;
import com.example.dietapp.photo.entity.ReactionType;

import java.time.LocalDateTime;

public record ReactionResponse(
        Long reactorId,
        String reactorNickname,
        ReactionType reactionType,
        LocalDateTime createdAt
) {
    public static ReactionResponse from(PhotoReaction reaction) {
        return new ReactionResponse(
                reaction.getReactor().getId(),
                reaction.getReactor().getNickname(),
                reaction.getReactionType(),
                reaction.getCreatedAt()
        );
    }
}
