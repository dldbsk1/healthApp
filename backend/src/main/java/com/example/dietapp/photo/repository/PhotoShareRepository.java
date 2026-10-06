package com.example.dietapp.photo.repository;

import com.example.dietapp.photo.entity.PhotoShare;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PhotoShareRepository extends JpaRepository<PhotoShare, Long> {

<<<<<<< HEAD
    Optional<PhotoShare> findByReceiverIdAndSharedDate(Long receiverId, LocalDate sharedDate);
=======
    List<PhotoShare> findByReceiverIdAndSharedDateOrderByCreatedAtDesc(Long receiverId, LocalDate sharedDate);
>>>>>>> 525ff0a (backend)

    List<PhotoShare> findByPhotoLogId(Long photoLogId);

    Optional<PhotoShare> findByIdAndReceiverId(Long id, Long receiverId);
<<<<<<< HEAD
}
=======

    List<PhotoShare> findBySharedDate(LocalDate sharedDate);
}
>>>>>>> 525ff0a (backend)
