package com.example.dietapp.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** local 프로필: /files/** 정적 서빙 */
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
