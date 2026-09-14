package com.example.dietapp.exercise.entity;

import com.example.dietapp.user.entity.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "exercise_logs")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ExerciseLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "exercise_log_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "exercise_name", nullable = false)
    private String exerciseName;

    @Column(name = "duration_min")
    private Integer durationMin;

    private Integer sets;

    private Integer reps;

    @Column(name = "calories_burned")
    private Integer caloriesBurned;

    /** 자세 분석 서버가 산출한 정확도 점수 (0~100) */
    private Double score;

    /** 자세 분석 서버가 산출한 피드백 텍스트 */
    @Lob
    private String feedback;

    @Column(name = "exercised_at", nullable = false)
    private LocalDateTime exercisedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public ExerciseLog(User user, String exerciseName, Integer durationMin, Integer sets,
                        Integer reps, Integer caloriesBurned, Double score, String feedback,
                        LocalDateTime exercisedAt) {
        this.user = user;
        this.exerciseName = exerciseName;
        this.durationMin = durationMin;
        this.sets = sets;
        this.reps = reps;
        this.caloriesBurned = caloriesBurned;
        this.score = score;
        this.feedback = feedback;
        this.exercisedAt = exercisedAt;
    }

    /** 자세 분석 서버 결과가 나중에 도착했을 때 갱신 */
    public void updateAnalysisResult(Double score, String feedback, Integer caloriesBurned) {
        this.score = score;
        this.feedback = feedback;
        this.caloriesBurned = caloriesBurned;
    }
}
