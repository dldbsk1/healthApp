package com.example.dietapp.user.service;

import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

/** userId(숫자 ID or 이메일) → users.user_id */
@Component
@RequiredArgsConstructor
public class UserIdResolver {

    private final UserRepository userRepository;

    public Optional<User> findUser(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return Optional.empty();
        }
        String value = identifier.trim();
        if (value.matches("\\d{1,18}")) {
            Optional<User> byId = userRepository.findById(Long.valueOf(value));
            if (byId.isPresent()) {
                return byId;
            }
        }
        return userRepository.findByEmail(value);
    }

    public Optional<Long> findId(String identifier) {
        return findUser(identifier).map(User::getId);
    }

    /** 없으면 IllegalArgumentException (400) */
    public Long resolveId(String identifier) {
        return findId(identifier)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없어요."));
    }
}
