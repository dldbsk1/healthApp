//
//  AppConfig.swift
//  TipsyCut
//
//  서버 주소를 한 곳에서 관리. 실기기 테스트 시 이 두 값만 Mac의 로컬 IP로 바꾸면 됨.
//  (시뮬레이터는 localhost 그대로 동작)
//

import Foundation

enum AppConfig {
    // 예: 실기기 테스트 시 "192.168.0.12" 처럼 Mac의 로컬 IP로 교체
    static let host = "localhost"

    static let springBootBaseURL = "http://\(host):8080"
    static let poseServerWebSocketBase = "ws://\(host):8000"

    // TODO: JWT 로그인 붙이면 실제 로그인된 유저 id로 교체
    static let temporaryUserId = 1
}
