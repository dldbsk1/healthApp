package com.example.dietapp.user.service;

import com.example.dietapp.user.dto.SignupRequest;
import com.example.dietapp.user.dto.UserResponse;
import com.example.dietapp.user.dto.UserUpdateRequest;
import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    // 형식 불일치 = 예전 평문 비밀번호
    private static final Pattern BCRYPT_FORMAT = Pattern.compile("^\\$2[aby]?\\$\\d{2}\\$[./0-9A-Za-z]{53}$");
    private static final int BCRYPT_MAX_BYTES = 72; // BCrypt 최대 입력

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserResponse registerUser(SignupRequest request) {
        String email = request.email() == null ? "" : request.email().trim();
        if (email.isEmpty()) {
            throw new IllegalArgumentException("이메일을 입력해 주세요.");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("이미 가입된 이메일입니다.");
        }

        User user = User.builder()
                .email(email)
                .password(hash(request.password()))
                .nickname(cleanNickname(request.nickname()))
                .gender(request.gender())
                .age(request.age())
                .height(request.height())
                .weight(request.weight())
                .targetWeight(request.targetWeight())
                .activityLevel(request.activityLevel())
                .goal(request.goal())
                .dietType(request.dietPreference())
                .recommendedCalories(request.recommendedCalories())
                .build();
        return UserResponse.from(userRepository.save(user));
    }

    @Transactional
    public UserResponse login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 이메일입니다."));

        String stored = user.getPassword();
        if (password == null) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        if (isHashed(stored)) {
            if (!passwordEncoder.matches(password, stored)) {
                throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
            }
        } else {
            // 평문 계정: 일치 시 해시로 교체
            if (!constantTimeEquals(stored, password)) {
                throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
            }
            user.changePassword(hash(password));
        }
        return UserResponse.from(user);
    }

    @Transactional
    public void updateUserProfile(UserUpdateRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 이메일입니다."));

        // null 유지, "" 삭제
        if (request.nickname() != null) {
            user.changeNickname(cleanNickname(request.nickname()));
        }
        user.updateProfile(request.gender(), request.age(), request.height(), request.weight(),
                request.targetWeight(), request.activityLevel(), request.goal(),
                request.dietPreference(), request.recommendedCalories());
    }

    public UserResponse getUserProfile(String email) {
        return userRepository.findByEmail(email)
                .map(UserResponse::from)
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 이메일입니다."));
    }

    public static boolean isHashed(String value) {
        return value != null && BCRYPT_FORMAT.matcher(value).matches();
    }

    private String hash(String raw) {
        if (raw == null || raw.isEmpty()) {
            throw new IllegalArgumentException("비밀번호를 입력해 주세요.");
        }
        if (raw.getBytes(StandardCharsets.UTF_8).length > BCRYPT_MAX_BYTES) {
            throw new IllegalArgumentException("비밀번호가 너무 길어요. (영문·숫자 72자, 한글 24자 이내)");
        }
        return passwordEncoder.encode(raw);
    }

    private boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) return false;
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    // trim, 빈 값 null, 50자 제한
    private String cleanNickname(String raw) {
        if (raw == null) return null;
        String nickname = raw.trim();
        if (nickname.length() > 50) {
            throw new IllegalArgumentException("닉네임은 50자 이하로 입력해 주세요.");
        }
        return nickname.isEmpty() ? null : nickname;
    }
}
