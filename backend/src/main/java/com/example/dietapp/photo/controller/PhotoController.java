package com.example.dietapp.photo.controller;

import com.example.dietapp.photo.dto.request.ReactionRequest;
import com.example.dietapp.photo.dto.response.*;
import com.example.dietapp.photo.service.PhotoService;
import com.example.dietapp.global.common.ApiResponse;
import jakarta.validation.Valid;
import com.example.dietapp.user.service.UserIdResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

/**
 * SNS(사진)탭 API (userId: 숫자 ID or 이메일)
 * TODO: JWT 적용 시 @AuthenticationPrincipal Long userId 로 교체
 */
@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService photoService;
    private final UserIdResolver userIdResolver;

    /** 업로드 → 캘린더 저장 + 랜덤 유저 전송 */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<PhotoLogResponse> upload(
            @RequestParam String userId,
            @RequestParam("image") MultipartFile image,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String memo) {
        return ApiResponse.ok("사진이 등록됐어요.", photoService.upload(userIdResolver.resolveId(userId), image, category, memo));
    }

    /** 오늘 받은 사진 (미열람 시 잠금) */
    @GetMapping("/received/today")
    public ApiResponse<ReceivedPhotoResponse> getTodayReceived(@RequestParam String userId) {
        return ApiResponse.ok(photoService.getTodayReceived(userIdResolver.resolveId(userId)));
    }

    /** 열기 → 잠금 해제 */
    @PostMapping("/shares/{shareId}/open")
    public ApiResponse<ReceivedPhotoResponse> openReceived(
            @RequestParam String userId,
            @PathVariable Long shareId) {
        return ApiResponse.ok("사진을 열었어요.", photoService.openReceived(userIdResolver.resolveId(userId), shareId));
    }

    @PostMapping("/shares/{shareId}/reactions")
    public ApiResponse<ReactionResponse> react(
            @RequestParam String userId,
            @PathVariable Long shareId,
            @Valid @RequestBody ReactionRequest request) {
        return ApiResponse.ok("리액션을 보냈어요.", photoService.react(userIdResolver.resolveId(userId), shareId, request));
    }

    /** 월별 사진 날짜 */
    @GetMapping("/calendar")
    public ApiResponse<List<CalendarDayResponse>> getCalendar(
            @RequestParam String userId,
            @RequestParam int year,
            @RequestParam int month) {
        return ApiResponse.ok(photoService.getCalendar(userIdResolver.resolveId(userId), year, month));
    }

    /** 날짜별 상세 + 리액션 */
    @GetMapping
    public ApiResponse<PhotoDetailResponse> getDetail(
            @RequestParam String userId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        return ApiResponse.ok(photoService.getDetail(userIdResolver.resolveId(userId), date));
    }
}
