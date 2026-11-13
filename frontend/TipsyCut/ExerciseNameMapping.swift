//
//  ExerciseNameMapping.swift
//  TipsyCut
//
//  UI에 표시되는 운동 이름과 pose-server(EXERCISE_RULES) / Spring Boot 쪽이 기대하는
//  운동 이름이 정확히 일치하지 않을 수 있어서 매핑 테이블로 분리.
//
//  ⚠️ Exercise.recommendedList 의 실제 name 값들이 이 매핑의 key와 다르면
//     여기만 고치면 됩니다 (다른 파일들은 안 건드려도 됨).
//

import Foundation

enum ExerciseNameMapping {

    /// UI 이름 → 백엔드(pose-server, ExerciseLog) 이름
    private static let uiToBackend: [String: String] = [
        "니푸쉬업": "푸쉬업",
        "런지": "런지",
        "레그레이즈": "레그레이즈",
        "플랭크": "플랭크",
    ]

    static func backendName(for uiName: String) -> String? {
        uiToBackend[uiName]
    }

    /// pose-server가 지원하는 운동인지 확인 (지원 안 하면 웹소켓 연결 자체를 시도하지 않기 위함)
    static func isSupported(_ uiName: String) -> Bool {
        backendName(for: uiName) != nil
    }
}
