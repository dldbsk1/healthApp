package com.example.diettotalbackend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class PasswordConfig {

    // BCrypt: 같은 비밀번호도 매번 다른 해시가 만들어지고(솔트 내장), 해시에서 원래 비밀번호를 되돌릴 수 없습니다.
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
