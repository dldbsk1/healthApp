//
//  AppConfig.swift
//  TipsyCut
//

import Foundation

enum AppConfig {

    // ngrok 등 주소가 바뀔 때마다 이 두 줄만 갱신하면 됨
    static let springBootBaseURL = "https://reputation-saskatchewan-willing-taxes.trycloudflare.com/api"
    static let poseServerWebSocketBase = "https://shirts-miami-sophisticated-educated.trycloudflare.com"

    /// 식단/추천/음식분석/회원 API(dietTotalBackend, MongoDB)를 호출할 서버 주소.
    /// 사진·운동 API와 같은 서버에서 같이 돌아가면 아래 그대로 두고,
    /// 별도 서버(별도 터널)로 띄우고 있으면 그 주소로 바꾸면 된다.
    static let dietServerBaseURL = springBootBaseURL

    static let temporaryUserId = 7

    /// 로그인 없이 사용할 고정 사용자 ID
    /// - 서버(MongoDB)에 이미 가입돼 있는 계정의 이메일을 넣으면 됨
    /// - TipsyCutApp 시작 시 UserDefaults "userId"에 저장되어 앱 전체에서 사용됨
    static let fixedUserId = "7"

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
