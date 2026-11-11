package com.example.dietapp.photo.repository;

import com.example.dietapp.photo.entity.PhotoLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PhotoLogRepository extends JpaRepository<PhotoLog, Long> {

    Optional<PhotoLog> findByUserIdAndLogDate(Long userId, LocalDate logDate);

    @Query("""
            select p from PhotoLog p
            where p.user.id = :userId
              and p.logDate between :start and :end
            order by p.logDate asc
            """)
    List<PhotoLog> findAllInMonth(@Param("userId") Long userId,
                                   @Param("start") LocalDate start,
                                   @Param("end") LocalDate end);
}
