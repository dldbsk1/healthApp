package com.example.dietapp.global.file;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.UUID;

/**
 * AWS S3에 업로드. spring.profiles.active 에 "local"이 없을 때(=배포 환경) 기본으로 선택된다.
 * application.yml의 file.storage.s3.* 설정을 사용.
 * 버킷이 퍼블릭 읽기로 설정되어 있다는 전제로 URL을 바로 조립한다 —
 * 비공개 버킷을 쓸 거면 presigned URL 발급 방식으로 바꿔야 한다.
 */
@Slf4j
@Service
@Profile("!local")
public class S3FileStorageService implements FileStorageService {

    private final S3Client s3Client;

    @Value("${file.storage.s3.bucket}")
    private String bucket;

    @Value("${file.storage.s3.region}")
    private String region;

    public S3FileStorageService(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @Override
    public String upload(MultipartFile file, String directory) {
        validate(file);

        String ext = extractExtension(file.getOriginalFilename());
        String key = directory + "/" + UUID.randomUUID() + ext;

        try {
            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();

            s3Client.putObject(request, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
        } catch (IOException e) {
            throw new UncheckedIOException("S3 업로드에 실패했습니다.", e);
        }

        String url = String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, key);
        log.info("[S3FileStorage] 업로드 완료: {}", url);
        return url;
    }

    private void validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 파일이 비어있습니다.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("이미지 파일만 업로드할 수 있습니다.");
        }
    }

    private String extractExtension(String originalFilename) {
        if (!StringUtils.hasText(originalFilename) || !originalFilename.contains(".")) {
            return "";
        }
        return originalFilename.substring(originalFilename.lastIndexOf('.'));
    }
}
