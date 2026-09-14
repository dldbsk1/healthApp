package com.example.dietapp.global.file;

import org.springframework.web.multipart.MultipartFile;

/**
 * 파일 저장소 추상화. local(디스크) / s3 구현체를 프로필로 전환한다.
 * 로컬 개발: application-local.yml에서 spring.profiles.active=local
 * 배포:      해당 프로필 없이 실행 (S3FileStorageService가 기본으로 선택됨)
 */
public interface FileStorageService {

    /**
     * @param file      업로드할 파일
     * @param directory 저장 하위 경로 (예: "photos", "diet")
     * @return 저장된 파일에 접근 가능한 URL
     */
    String upload(MultipartFile file, String directory);
}
