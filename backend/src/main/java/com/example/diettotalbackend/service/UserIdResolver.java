package com.example.diettotalbackend.service;

import com.example.diettotalbackend.entity.User;
import com.example.diettotalbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * 프론트가 보내는 userId는 이메일일 수도, 숫자 ID일 수도 있어서(기존 MongoDB 데이터에도 섞여 있었음)
 * 어느 쪽이 와도 users.user_id(Long)로 바꿔주는 변환기입니다.
 * - 숫자만 있으면 user_id로 먼저 조회하고, 없으면 이메일로 조회합니다.
 * - 못 찾으면(예: "temp_user", 예전 ObjectId 문자열) 비어 있는 결과를 돌려줍니다.
 */
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

    /** 못 찾으면 IllegalArgumentException (컨트롤러가 400으로 응답) */
    public Long resolveId(String identifier) {
        return findId(identifier)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없어요."));
    }
}
