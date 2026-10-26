package com.example.diettotalbackend.config;

import com.example.diettotalbackend.entity.User;
import com.example.diettotalbackend.repository.UserRepository;
import com.example.diettotalbackend.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * [1회용] DB에 평문으로 남아 있는 비밀번호를 BCrypt 해시로 일괄 변환합니다.
 * - 기본은 꺼져 있습니다. application.properties 에 app.security.migrate-plain-passwords=true 로 바꾸고
 *   서버를 한 번 실행한 뒤, 반드시 false 로 되돌리세요.
 * - 이미 해시인 비밀번호는 건드리지 않아 여러 번 실행해도 안전합니다.
 * - 로그에는 개수만 남기고 비밀번호는 절대 출력하지 않습니다.
 * - 같은 DB를 쓰는 다른 서버(팀원 서버 등)가 평문 비교로 로그인을 처리한다면, 변환 후 그쪽 로그인이 깨집니다.
 * - 변환하지 않아도 로그인 시점에 자동으로 해시로 교체됩니다. (UserService.login)
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
                skipped++; // BCrypt가 처리할 수 없는 길이 — 해당 사용자는 로그인 시 오류 안내
            } else {
                user.setPassword(passwordEncoder.encode(stored));
                userRepository.save(user);
                converted++;
            }
        }
        log.info("[PasswordMigration] 변환 {}건, 이미 해시 {}건, 건너뜀 {}건", converted, alreadyHashed, skipped);
    }
}
