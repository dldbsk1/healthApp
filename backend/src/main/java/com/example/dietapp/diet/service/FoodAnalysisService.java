package com.example.dietapp.diet.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.time.Duration;

@Service
public class FoodAnalysisService {

    private final WebClient webClient;

    private static final Duration TIMEOUT = Duration.ofSeconds(60);

    public FoodAnalysisService(@Value("${ai.diet.base-url}") String dietAiBaseUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(dietAiBaseUrl)
                .build();
    }

    public String analyzeFoodImage(MultipartFile file, double thickness) throws IOException {

        MultipartBodyBuilder builder = new MultipartBodyBuilder();
        builder.part("file", new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        }, MediaType.parseMediaType(file.getContentType()));

        builder.part("thickness", thickness);

        MultiValueMap<String, HttpEntity<?>> multipartBody = builder.build();

        return webClient.post()
                .uri("/analyze-food/")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(multipartBody))
                .retrieve()
                .bodyToMono(String.class)
                .block(TIMEOUT);
    }
}