package com.example.dietapp.photo.controller;

import com.example.dietapp.photo.dto.request.ReactionRequest;
import com.example.dietapp.photo.dto.response.*;
import com.example.dietapp.photo.service.PhotoService;
import com.example.dietapp.global.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

/**
 * SNS(사진)탭 API.
 * TODO: JWT 인증 붙이면 @RequestParam Long userId → @AuthenticationPrincipal Long userId 로 되돌리기
 */
@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService photoService;

    /** 사진 등록(실제 이미지 파일 업로드) → 달력 자동 저장 + 랜덤 유저에게 전송 */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<PhotoLogResponse> upload(
            @RequestParam Long userId,
            @RequestParam("image") MultipartFile image,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String memo) {
        return ApiResponse.ok("사진이 등록됐어요.", photoService.upload(userId, image, category, memo));
    }

    /** 오늘 받은 사진 (밤 9시 전이면 잠금 상태로 응답) */
    @GetMapping("/received/today")
    public ApiResponse<ReceivedPhotoResponse> getTodayReceived(@RequestParam Long userId) {
        return ApiResponse.ok(photoService.getTodayReceived(userId));
    }

    /** 받은 사진에 리액션 보내기 */
    @PostMapping("/shares/{shareId}/reactions")
    public ApiResponse<ReactionResponse> react(
            @RequestParam Long userId,
            @PathVariable Long shareId,
            @Valid @RequestBody ReactionRequest request) {
        return ApiResponse.ok("리액션을 보냈어요.", photoService.react(userId, shareId, request));
    }

    /** 캘린더 - 이번 달 중 사진 있는 날짜 목록 */
    @GetMapping("/calendar")
    public ApiResponse<List<CalendarDayResponse>> getCalendar(
            @RequestParam Long userId,
            @RequestParam int year,
            @RequestParam int month) {
        return ApiResponse.ok(photoService.getCalendar(userId, year, month));
    }

    /** 특정 날짜 사진 상세 (확대 + 리액션 목록) */
    @GetMapping
    public ApiResponse<PhotoDetailResponse> getDetail(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        return ApiResponse.ok(photoService.getDetail(userId, date));
    }
}
