package com.example.dietapp.global.common;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/** 하루 기준: 새벽 4시 시작 (예: 10/29 02:00 → 10/28) */
public final class LogicalDay {

    public static final LocalTime DAY_START = LocalTime.of(4, 0);

    private LogicalDay() {
    }

    public static LocalDate today() {
        return of(LocalDateTime.now());
    }

    public static LocalDate of(LocalDateTime dateTime) {
        LocalDate date = dateTime.toLocalDate();
        return dateTime.toLocalTime().isBefore(DAY_START) ? date.minusDays(1) : date;
    }

    /** 당일 04:00 */
    public static LocalDateTime start(LocalDate date) {
        return date.atTime(DAY_START);
    }

    /** 다음 날 03:59:59.999999 */
    public static LocalDateTime end(LocalDate date) {
        return date.plusDays(1).atTime(DAY_START).minusNanos(1_000);
    }
}
