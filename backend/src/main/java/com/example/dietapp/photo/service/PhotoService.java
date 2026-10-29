package com.example.dietapp.photo.service;

import com.example.dietapp.photo.dto.request.ReactionRequest;
import com.example.dietapp.photo.dto.response.*;
import com.example.dietapp.photo.entity.PhotoLog;
import com.example.dietapp.photo.entity.PhotoReaction;
import com.example.dietapp.photo.entity.PhotoShare;
import com.example.dietapp.photo.repository.PhotoLogRepository;
import com.example.dietapp.photo.repository.PhotoReactionRepository;
import com.example.dietapp.photo.repository.PhotoShareRepository;
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

    // ───────────────────────── 업로드 + 랜덤 전송 ─────────────────────────

    @Transactional
    public PhotoLogResponse upload(Long userId, MultipartFile image, String category, String memo) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("존재하지 않는 사용자입니다. id=" + userId));

        String imageUrl = fileStorageService.upload(image, "photos");

        // 오늘 이미 올린 기록이 있으면 새로 만들지 않고 덮어쓴다.
        // (PhotoShare는 photoLog를 참조만 하고 있어서, 받은 사람도 자동으로 새 이미지를 보게 됨 —
        //  이미 전송은 끝났으니 랜덤 전송을 다시 할 필요는 없음)
        Optional<PhotoLog> existing = photoLogRepository.findByUserIdAndLogDate(userId, LocalDate.now());

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
                .logDate(LocalDate.now())
                .build();
        photoLogRepository.save(photoLog);

        assignRandomReceiver(photoLog, user);

        return PhotoLogResponse.from(photoLog);
    }

    /** 업로더 본인을 제외한 유저 중 한 명을 무작위로 골라 오늘 날짜로 전송(PhotoShare 생성) */
    private void assignRandomReceiver(PhotoLog photoLog, User uploader) {
        List<User> candidates = userRepository.findAll().stream()
                .filter(u -> !u.getId().equals(uploader.getId()))
                .toList();

        if (candidates.isEmpty()) {
            return; // 받을 사람이 없으면(유저 1명뿐인 경우 등) 그냥 스킵
        }

        User receiver = candidates.get((int) (Math.random() * candidates.size()));

        PhotoShare share = PhotoShare.builder()
                .photoLog(photoLog)
                .receiver(receiver)
                .sharedDate(LocalDate.now())
                .build();
        photoShareRepository.save(share);
    }

    // ───────────────────────── 오늘 받은 사진 ('열기' 버튼으로 잠금 해제) ─────────────────────────

    public ReceivedPhotoResponse getTodayReceived(Long userId) {
        List<PhotoShare> shares =
                photoShareRepository.findByReceiverIdAndSharedDateOrderByCreatedAtDesc(userId, LocalDate.now());

        if (shares.isEmpty()) {
            return ReceivedPhotoResponse.lockedResponse(); // 오늘 받은 사진 없음 (shareId == null)
        }

        PhotoShare share = shares.get(0);  // 가장 최근에 받은 것 1개만 보여줌

        if (!share.isOpened()) {
            return ReceivedPhotoResponse.lockedResponse(share.getId()); // 도착은 했지만 아직 안 열어봄
        }

        return toUnlockedResponse(share);
    }

    /** '열기' 버튼 → 잠금 해제 후 사진/리액션 응답. 이미 열려 있어도 같은 결과를 돌려줌(멱등). */
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

    // ───────────────────────── 리액션 ─────────────────────────

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

    // ───────────────────────── 캘린더 (본인이 올린 사진 아카이브) ─────────────────────────

    public List<CalendarDayResponse> getCalendar(Long userId, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        return photoLogRepository.findAllInMonth(userId, start, end).stream()
                .map(p -> new CalendarDayResponse(p.getLogDate(), p.getImageUrl()))
                .toList();
    }

    // ───────────────────────── 날짜별 상세 (확대 + 리액션) ─────────────────────────

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
