//
//  APIconfig.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 9/14/26.
//

// APIConfig.swift
import Foundation

struct APIConfig {
    // 로컬 테스트용 기본 URL
    static let baseURL = "http://127.0.0.1:8000/api/v1"
    
    // 엔드포인트 생성 함수
    static func endpoint(_ path: String) -> URL? {
        return URL(string: "\(baseURL)\(path)")
    }
}
