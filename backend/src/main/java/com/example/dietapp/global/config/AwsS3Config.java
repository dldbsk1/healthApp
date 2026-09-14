package com.example.dietapp.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * S3Client 는 AWS 자격증명(환경변수 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 또는
 * ~/.aws/credentials)을 기본 자격증명 체인으로 자동 인식합니다.
 * local 프로필로 실행할 땐 아예 이 빈을 만들지 않아서, AWS 키 없이도 로컬 개발이 가능합니다.
 */
@Configuration
@Profile("!local")
public class AwsS3Config {

    @Value("${file.storage.s3.region}")
    private String region;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                .build();
    }
}
