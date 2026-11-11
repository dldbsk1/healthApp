package com.example.dietapp.photo.dto.request;

import com.example.dietapp.photo.entity.ReactionType;
import jakarta.validation.constraints.NotNull;

public record ReactionRequest(
        @NotNull(message = "리액션 종류는 필수입니다.")
        ReactionType reactionType
) {
}
