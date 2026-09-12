package com.example.diettotalbackend.service;

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

    // 로컬에서 구동 중인 FastAPI 서버 주소 지정
    private final WebClient webClient = WebClient.builder()
            .baseUrl("http://127.0.0.1:8000")
            .build();

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