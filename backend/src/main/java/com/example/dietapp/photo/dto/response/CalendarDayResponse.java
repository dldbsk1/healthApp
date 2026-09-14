package com.example.dietapp.photo.dto.response;

import java.time.LocalDate;

public record CalendarDayResponse(
        LocalDate date,
        String thumbnailUrl
) {
}
