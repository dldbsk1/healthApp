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

/**
 * 업로드된 PhotoLog 하나가 랜덤으로 어떤 유저(receiver)에게 전송됐는지 기록.
 * "밤 9시 공개" 잠금 로직은 저장 시각이 아니라 조회 시점에 LocalTime 비교로 처리한다 (서비스 계층 참고).
 */
@Entity
@Table(name = "photo_shares")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PhotoShare {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "photo_id", nullable = false)
    private PhotoLog photoLog;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false)
    private User receiver;

    /** photoLog.logDate 와 동일 — 조회 편의를 위해 비정규화 */
    @Column(name = "shared_date", nullable = false)
    private LocalDate sharedDate;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public PhotoShare(PhotoLog photoLog, User receiver, LocalDate sharedDate) {
        this.photoLog = photoLog;
        this.receiver = receiver;
        this.sharedDate = sharedDate;
    }
}
