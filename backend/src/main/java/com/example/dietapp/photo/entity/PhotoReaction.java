package com.example.dietapp.photo.entity;

import com.example.dietapp.user.entity.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "photo_reactions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"photo_share_id", "reactor_id", "reaction_type"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PhotoReaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "photo_share_id", nullable = false)
    private PhotoShare photoShare;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reactor_id", nullable = false)
    private User reactor;

    @Enumerated(EnumType.STRING)
    @Column(name = "reaction_type", nullable = false)
    private ReactionType reactionType;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public PhotoReaction(PhotoShare photoShare, User reactor, ReactionType reactionType) {
        this.photoShare = photoShare;
        this.reactor = reactor;
        this.reactionType = reactionType;
    }
}
