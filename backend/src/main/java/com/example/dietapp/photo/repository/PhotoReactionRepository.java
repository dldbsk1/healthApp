package com.example.dietapp.photo.repository;

import com.example.dietapp.photo.entity.PhotoReaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PhotoReactionRepository extends JpaRepository<PhotoReaction, Long> {

    List<PhotoReaction> findByPhotoShareId(Long photoShareId);

    List<PhotoReaction> findByPhotoShareIdIn(List<Long> photoShareIds);

    boolean existsByPhotoShareIdAndReactorIdAndReactionType(
            Long photoShareId, Long reactorId, com.example.dietapp.photo.entity.ReactionType reactionType);
}
