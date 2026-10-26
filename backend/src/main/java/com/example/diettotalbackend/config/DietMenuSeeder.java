package com.example.diettotalbackend.config;

import com.example.diettotalbackend.entity.DietMenu;
import com.example.diettotalbackend.repository.DietMenuRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.List;

/**
 * 서버를 시작할 때 src/main/resources/diet_menu_seed.json 을 읽어서 diet_menus 에 반영합니다.
 * - foodName 이 같은 메뉴는 값을 갱신하고, 없으면 새로 추가합니다. (같은 파일을 여러 번 올려도 중복 없음)
 * - 추천 점수화용 필드(tags, heaviness)도 함께 반영합니다.
 * - 끄고 싶으면 application.properties 에 app.seed.diet-menus.enabled=false
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.seed.diet-menus.enabled", havingValue = "true", matchIfMissing = true)
public class DietMenuSeeder implements ApplicationRunner {

    private static final String SEED_PATH = "diet_menu_seed.json";

    private final DietMenuRepository dietMenuRepository;
    private final ObjectMapper objectMapper;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        ClassPathResource resource = new ClassPathResource(SEED_PATH);
        if (!resource.exists()) {
            return;
        }

        List<DietMenu> items;
        try (InputStream in = resource.getInputStream()) {
            items = objectMapper.readValue(in, new TypeReference<List<DietMenu>>() {});
        }

        int inserted = 0;
        int updated = 0;
        for (DietMenu item : items) {
            if (item.getFoodName() == null || item.getFoodName().isBlank()) {
                continue;
            }
            String name = item.getFoodName().trim();
            DietMenu target = dietMenuRepository.findByFoodName(name).orElse(null);
            if (target == null) {
                target = new DietMenu();
                inserted++;
            } else {
                updated++;
            }
            target.setFoodName(name);
            target.setCalories(item.getCalories());
            target.setCarbs(item.getCarbs());
            target.setProtein(item.getProtein());
            target.setFat(item.getFat());
            target.setDietType(item.getDietType());
            target.setPairedDrink(item.getPairedDrink());
            target.setImageUrl(item.getImageUrl());
            target.setTags(item.getTags());
            target.setHeaviness(item.getHeaviness());
            dietMenuRepository.save(target);
        }
        log.info("[DietMenuSeeder] 메뉴 {}건 반영 (추가 {}, 갱신 {})", inserted + updated, inserted, updated);
    }
}