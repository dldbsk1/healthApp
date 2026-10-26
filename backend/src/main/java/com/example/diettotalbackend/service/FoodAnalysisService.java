package com.example.diettotalbackend.service;

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

@Service
public class FoodAnalysisService {

    private final WebClient webClient;

    // application.properties의 ai.server.url 값으로 파이썬 서버 주소를 지정
    // (환경변수 AI_SERVER_URL이 없으면 같은 컴퓨터의 http://127.0.0.1:8000 사용)
    public FoodAnalysisService(@Value("${ai.server.url}") String aiServerUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(aiServerUrl)
                .build();
    }

    // 💡 파라미터에 thickness 추가
    public String analyzeFoodImage(MultipartFile file, double thickness) throws IOException {

        MultipartBodyBuilder builder = new MultipartBodyBuilder();
        builder.part("file", new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        }, MediaType.parseMediaType(file.getContentType()));

        // 💡 [추가] AR 두께 데이터도 파이썬으로 함께 넘겨줍니다!
        builder.part("thickness", thickness);

        MultiValueMap<String, HttpEntity<?>> multipartBody = builder.build();

        return webClient.post()
                .uri("/analyze-food/")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(multipartBody))
                .retrieve()
                .bodyToMono(String.class)
                .block();
    }
}