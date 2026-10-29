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

    /** receiver가 '열기'를 눌렀는지. 컬럼 추가 전 기존 데이터(null)는 false로 취급하려고 Boolean(래퍼)을 씀 */
    @Column(name = "opened")
    private Boolean opened = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public PhotoShare(PhotoLog photoLog, User receiver, LocalDate sharedDate) {
        this.photoLog = photoLog;
        this.receiver = receiver;
        this.sharedDate = sharedDate;
    }

    public boolean isOpened() {
        return Boolean.TRUE.equals(opened);
    }

    public void open() {
        this.opened = true;
    }
}
