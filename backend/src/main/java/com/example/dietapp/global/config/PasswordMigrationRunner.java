package com.example.dietapp.global.config;

import com.example.dietapp.user.entity.User;
import com.example.dietapp.user.repository.UserRepository;
import com.example.dietapp.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * [1회용] 평문 비밀번호 → BCrypt 일괄 변환
 *  - app.security.migrate-plain-passwords=true 로 1회 실행 후 false 복구
 *  - 이미 해시면 skip, 로그엔 개수만
 *  - 미실행 시에도 로그인 때 자동 변환
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.security.migrate-plain-passwords", havingValue = "true")
public class PasswordMigrationRunner implements ApplicationRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(ApplicationArguments args) {
        int converted = 0;
        int alreadyHashed = 0;
        int skipped = 0;

        for (User user : userRepository.findAll()) {
            String stored = user.getPassword();
            if (stored == null || stored.isEmpty()) {
                skipped++;
            } else if (UserService.isHashed(stored)) {
                alreadyHashed++;
            } else if (stored.getBytes(StandardCharsets.UTF_8).length > 72) {
                skipped++; // 72바이트 초과
            } else {
                user.changePassword(passwordEncoder.encode(stored));
                userRepository.save(user);
                converted++;
            }
        }
        log.info("[PasswordMigration] 변환 {}건, 이미 해시 {}건, 건너뜀 {}건", converted, alreadyHashed, skipped);
    }
}
