package com.example.dietapp.photo.entity;

import com.example.dietapp.user.entity.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "photo_logs")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PhotoLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "photo_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String category;

    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    private String memo;

    @Column(name = "log_date", nullable = false)
    private LocalDate logDate;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public PhotoLog(User user, String category, String imageUrl, String memo, LocalDate logDate) {
        this.user = user;
        this.category = category;
        this.imageUrl = imageUrl;
        this.memo = memo;
        this.logDate = logDate;
    }
}
