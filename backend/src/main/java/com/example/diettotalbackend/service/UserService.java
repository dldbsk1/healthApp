package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.User; // 💡 entity 패키지로 import 변경
import com.example.diettotalbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.example.diettotalbackend.dto.UserUpdateRequest;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class UserService {
    // BCrypt 해시 형식 ($2a$10$ + 53자). 이 형식이 아니면 예전에 평문으로 저장된 비밀번호로 봅니다.
    private static final Pattern BCRYPT_FORMAT = Pattern.compile("^\\$2[aby]?\\$\\d{2}\\$[./0-9A-Za-z]{53}$");
    private static final int BCRYPT_MAX_BYTES = 72; // BCrypt가 처리하는 최대 길이

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public User registerUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("이미 가입된 이메일입니다.");
        }
        user.setNickname(cleanNickname(user.getNickname()));
        user.setPassword(hash(user.getPassword())); // 평문 대신 해시로 저장
        user.setId(null); // 요청에 id가 섞여 와도 기존 사용자를 덮어쓰지 않도록 항상 새 행으로 저장
        return userRepository.save(user);
    }

    public User login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));

        String stored = user.getPassword();
        if (password == null) {
            throw new RuntimeException("비밀번호가 일치하지 않습니다.");
        }

        if (isHashed(stored)) {
            if (!passwordEncoder.matches(password, stored)) {
                throw new RuntimeException("비밀번호가 일치하지 않습니다.");
            }
        } else {
            // 예전에 평문으로 저장된 계정: 맞으면 로그인시키고, 그 자리에서 해시로 교체
            if (!constantTimeEquals(stored, password)) {
                throw new RuntimeException("비밀번호가 일치하지 않습니다.");
            }
            user.setPassword(hash(password));
            userRepository.save(user);
        }

        return user;
    }
    public void updateUserProfile(UserUpdateRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));

        // 닉네임은 요청에 값이 있을 때만 바꿈 (없으면 기존 값 유지)
        if (request.getNickname() != null) {
            user.setNickname(cleanNickname(request.getNickname()));
        }

        user.setGender(request.getGender());
        user.setAge(request.getAge());
        user.setHeight(request.getHeight());
        user.setWeight(request.getWeight());
        user.setActivityLevel(request.getActivityLevel());
        user.setGoal(request.getGoal());
        user.setDietPreference(request.getDietPreference());

        // 새로 계산된 권장 칼로리 덮어쓰기
        user.setRecommendedCalories(request.getRecommendedCalories());

        userRepository.save(user);
    }
    // BCrypt 해시로 이미 바뀐 값인지 확인
    public static boolean isHashed(String value) {
        return value != null && BCRYPT_FORMAT.matcher(value).matches();
    }

    private String hash(String raw) {
        if (raw == null || raw.isEmpty()) {
            throw new RuntimeException("비밀번호를 입력해 주세요.");
        }
        if (raw.getBytes(StandardCharsets.UTF_8).length > BCRYPT_MAX_BYTES) {
            throw new RuntimeException("비밀번호가 너무 길어요. (영문·숫자 72자, 한글 24자 이내)");
        }
        return passwordEncoder.encode(raw);
    }

    private boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) return false;
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    // 닉네임: 앞뒤 공백 제거, 비어 있으면 null, 50자 초과는 거절
    private String cleanNickname(String raw) {
        if (raw == null) return null;
        String nickname = raw.trim();
        if (nickname.length() > 50) {
            throw new RuntimeException("닉네임은 50자 이하로 입력해 주세요.");
        }
        return nickname.isEmpty() ? null : nickname;
    }

    public User getUserProfile(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("가입되지 않은 이메일입니다."));
    }
}