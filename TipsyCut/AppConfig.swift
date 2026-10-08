//
//  AppConfig.swift
//  TipsyCut
//

import Foundation

enum AppConfig {

    // ngrok 등 주소가 바뀔 때마다 이 두 줄만 갱신하면 됨
    static let springBootBaseURL = "https://reduction-precipitation-significance-wheel.trycloudflare.com"
    static let poseServerWebSocketBase = "https://karl-arabic-baskets-invited.trycloudflare.com"

    /// 식단/추천/음식분석/회원 API(dietTotalBackend, MongoDB)를 호출할 서버 주소.
    /// 사진·운동 API와 같은 서버에서 같이 돌아가면 아래 그대로 두고,
    /// 별도 서버(별도 터널)로 띄우고 있으면 그 주소로 바꾸면 된다.
    static let dietServerBaseURL = springBootBaseURL

    static let temporaryUserId = 1
    /// 서버가 돌려준 이미지 경로를 실제 접속 가능한 URL로 변환.
    /// - "/files/photos/xxx.jpg" 처럼 상대경로면 → springBootBaseURL 붙여서 완성
    /// - "https://..." 처럼 이미 완전한 URL(S3 등)이면 → 그대로 사용
    static func resolvedImageURL(_ path: String) -> URL? {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        return URL(string: springBootBaseURL + path)
    }
}
