package com.example.diettotalbackend.config;

import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.List;

@Component
@RequiredArgsConstructor
public class DietMenuDataLoader implements CommandLineRunner {

    private final DietMenuRepository repository;
    private final ObjectMapper objectMapper;

    @Override
    public void run(String... args) throws Exception {
        // 💡 핵심: 기존 DB에 있던 옛날 "와인" 데이터를 싹 지우고 강제 리셋합니다.
        repository.deleteAll();

        try (InputStream inputStream = new ClassPathResource("diet_menu_seed.json").getInputStream()) {
            List<DietMenu> menus = objectMapper.readValue(inputStream, new TypeReference<List<DietMenu>>() {});
            repository.saveAll(menus);
            System.out.println("✅ [System] 자체 다이어트 메뉴 " + menus.size() + "개 DB 리셋 및 최신화 완료!");
        } catch (Exception e) {
            System.err.println("❌ [Error] 초기 데이터 저장 실패: " + e.getMessage());
        }
    }
}
