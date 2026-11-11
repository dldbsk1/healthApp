package com.example.dietapp.global.file;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 /**
  * local 프로필: 디스크 저장
  * 상대경로(/files/...)만 반환 → 클라이언트가 현재 서버 주소를 붙임 (localhost 고정 방지)
  */
@Slf4j
@Service
@Profile("local")
public class LocalFileStorageService implements FileStorageService {

    @Value("${file.storage.local.base-dir}")
    private String baseDir;

    @Override
    public String upload(MultipartFile file, String directory) {
        validate(file);

        String ext = extractExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID() + ext;

        Path targetDir = Path.of(baseDir, directory);
        Path targetPath = targetDir.resolve(filename);

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new UncheckedIOException("파일 저장에 실패했습니다.", e);
        }

        String relativePath = "/files/" + directory + "/" + filename;
        log.info("[LocalFileStorage] 저장 완료: {}", relativePath);
        return relativePath;
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
