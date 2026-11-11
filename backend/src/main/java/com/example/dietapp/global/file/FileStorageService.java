package com.example.dietapp.global.file;

import org.springframework.web.multipart.MultipartFile;

/** 파일 저장소 (local: 디스크 / 그 외: S3) */
public interface FileStorageService {

    /** @return 접근 URL (local 은 상대경로) */
    String upload(MultipartFile file, String directory);
}
