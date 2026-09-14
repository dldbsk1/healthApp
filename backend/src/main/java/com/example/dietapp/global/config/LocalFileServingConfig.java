package com.example.dietapp.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** local 프로필에서만 필요 (S3 쓸 때는 S3 URL을 그대로 쓰므로 이 설정 자체가 불필요) */
@Configuration
@Profile("local")
public class LocalFileServingConfig implements WebMvcConfigurer {

    @Value("${file.storage.local.base-dir}")
    private String baseDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = baseDir.endsWith("/") ? "file:" + baseDir : "file:" + baseDir + "/";
        registry.addResourceHandler("/files/**")
                .addResourceLocations(location);
    }
}
