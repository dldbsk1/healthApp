package com.example.dietapp.exercise.repository;

import com.example.dietapp.exercise.entity.ExerciseLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ExerciseLogRepository extends JpaRepository<ExerciseLog, Long> {

    List<ExerciseLog> findByUserIdAndExercisedAtBetweenOrderByExercisedAtDesc(
            Long userId, LocalDateTime start, LocalDateTime end);

    Optional<ExerciseLog> findByIdAndUserId(Long id, Long userId);

    @Query("""
            select coalesce(sum(e.caloriesBurned), 0)
            from ExerciseLog e
            where e.user.id = :userId
              and e.exercisedAt between :start and :end
            """)
    Integer sumCaloriesBurned(@Param("userId") Long userId,
                              @Param("start") LocalDateTime start,
                              @Param("end") LocalDateTime end);

    @Query("""
            select coalesce(sum(e.durationMin), 0)
            from ExerciseLog e
            where e.user.id = :userId
              and e.exercisedAt between :start and :end
            """)
    Integer sumDurationMin(@Param("userId") Long userId,
                           @Param("start") LocalDateTime start,
                           @Param("end") LocalDateTime end);

    long countByUserIdAndExercisedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}
