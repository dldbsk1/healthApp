package com.example.dietapp.photo.service;

import com.example.dietapp.photo.dto.request.ReactionRequest;
import com.example.dietapp.photo.dto.response.*;
import com.example.dietapp.photo.entity.PhotoLog;
import com.example.dietapp.photo.entity.PhotoReaction;
import com.example.dietapp.photo.entity.PhotoShare;
import com.example.dietapp.photo.repository.PhotoLogRepository;
import com.example.dietapp.photo.repository.PhotoReactionRepository;
import com.example.dietapp.photo.repository.PhotoShareRepository;
import com.example.dietapp.global.common.LogicalDay;
import com.example.dietapp.global.file.FileStorageService;
import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import com.example.dietapp.global.exception.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PhotoService {

    private final PhotoLogRepository photoLogRepository;
    private final PhotoShareRepository photoShareRepository;
    private final PhotoReactionRepository photoReactionRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    @Transactional
    public PhotoLogResponse upload(Long userId, MultipartFile image, String category, String memo) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("존재하지 않는 사용자입니다. id=" + userId));

        String imageUrl = fileStorageService.upload(image, "photos");

        // 같은 날 재업로드: 덮어쓰기 (공유는 참조라 재전송 불필요)
        Optional<PhotoLog> existing = photoLogRepository.findByUserIdAndLogDate(userId, LogicalDay.today());

        if (existing.isPresent()) {
            PhotoLog photoLog = existing.get();
            photoLog.overwrite(category, imageUrl, memo);
            return PhotoLogResponse.from(photoLog);
        }

        PhotoLog photoLog = PhotoLog.builder()
                .user(user)
                .category(category)
                .imageUrl(imageUrl)
                .memo(memo)
                .logDate(LogicalDay.today())
                .build();
        photoLogRepository.save(photoLog);

        assignRandomReceiver(photoLog, user);

        return PhotoLogResponse.from(photoLog);
    }

    /** 본인 제외 랜덤 1명에게 전송 */
    private void assignRandomReceiver(PhotoLog photoLog, User uploader) {
        List<User> candidates = userRepository.findAll().stream()
                .filter(u -> !u.getId().equals(uploader.getId()))
                .toList();

        if (candidates.isEmpty()) {
            return; // 받을 사람 없음
        }

        User receiver = candidates.get((int) (Math.random() * candidates.size()));

        PhotoShare share = PhotoShare.builder()
                .photoLog(photoLog)
                .receiver(receiver)
                .sharedDate(LogicalDay.today())
                .build();
        photoShareRepository.save(share);
    }

    public ReceivedPhotoResponse getTodayReceived(Long userId) {
        List<PhotoShare> shares =
                photoShareRepository.findByReceiverIdAndSharedDateOrderByCreatedAtDesc(userId, LogicalDay.today());

        if (shares.isEmpty()) {
            return ReceivedPhotoResponse.lockedResponse();
        }

        PhotoShare share = shares.get(0);  // 최신 1개

        if (!share.isOpened()) {
            return ReceivedPhotoResponse.lockedResponse(share.getId());
        }

        return toUnlockedResponse(share);
    }

    /** 잠금 해제 (멱등) */
    @Transactional
    public ReceivedPhotoResponse openReceived(Long userId, Long shareId) {
        PhotoShare share = photoShareRepository.findByIdAndReceiverId(shareId, userId)
                .orElseThrow(() -> new EntityNotFoundException("전송받은 사진을 찾을 수 없습니다. id=" + shareId));

        share.open();
        return toUnlockedResponse(share);
    }

    private ReceivedPhotoResponse toUnlockedResponse(PhotoShare share) {
        List<ReactionResponse> reactions = photoReactionRepository.findByPhotoShareId(share.getId())
                .stream().map(ReactionResponse::from).toList();

        return new ReceivedPhotoResponse(
                false,
                share.getId(),
                share.getPhotoLog().getImageUrl(),
                share.getPhotoLog().getUser().getNickname(),
                reactions
        );
    }

    @Transactional
    public ReactionResponse react(Long userId, Long shareId, ReactionRequest request) {
        PhotoShare share = photoShareRepository.findByIdAndReceiverId(shareId, userId)
                .orElseThrow(() -> new EntityNotFoundException("전송받은 사진을 찾을 수 없습니다. id=" + shareId));

        if (!share.isOpened()) {
            throw new IllegalStateException("아직 열어보지 않은 사진입니다.");
        }

        boolean alreadyReacted = photoReactionRepository
                .existsByPhotoShareIdAndReactorIdAndReactionType(shareId, userId, request.reactionType());
        if (alreadyReacted) {
            throw new IllegalStateException("이미 같은 리액션을 보냈습니다.");
        }

        User reactor = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("존재하지 않는 사용자입니다. id=" + userId));

        PhotoReaction reaction = PhotoReaction.builder()
                .photoShare(share)
                .reactor(reactor)
                .reactionType(request.reactionType())
                .build();

        return ReactionResponse.from(photoReactionRepository.save(reaction));
    }

    public List<CalendarDayResponse> getCalendar(Long userId, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        return photoLogRepository.findAllInMonth(userId, start, end).stream()
                .map(p -> new CalendarDayResponse(p.getLogDate(), p.getImageUrl()))
                .toList();
    }

    public PhotoDetailResponse getDetail(Long userId, LocalDate date) {
        PhotoLog photoLog = photoLogRepository.findByUserIdAndLogDate(userId, date)
                .orElseThrow(() -> new EntityNotFoundException("해당 날짜의 사진이 없습니다: " + date));

        List<Long> shareIds = photoShareRepository.findByPhotoLogId(photoLog.getId())
                .stream().map(PhotoShare::getId).toList();

        List<ReactionResponse> reactions = shareIds.isEmpty()
                ? List.of()
                : photoReactionRepository.findByPhotoShareIdIn(shareIds).stream()
                .map(ReactionResponse::from).toList();

        return new PhotoDetailResponse(
                photoLog.getId(), photoLog.getImageUrl(), photoLog.getMemo(),
                photoLog.getLogDate(), reactions
        );
    }
}
