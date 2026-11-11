//
//  RootView.swift
//  TipsyCut
//
//  Created by mac16 on 8/28/26.
//

import SwiftUI

struct RootView: View {
    // 💡 로그인 여부를 저장하는 상태 변수
    // (AppStorage를 사용하면 앱을 껐다 켜도 로그인 상태가 유지됩니다)
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        Group {
            if isLoggedIn {
                // 1. 로그인 성공 상태: 하단 탭 바가 포함된 메인 뷰로 이동
                MainTabView()
            } else {
                // 2. 로그인 전 상태: 웰컴 뷰 ➔ 로그인 뷰 흐름으로 진행
                NavigationStack {
                    WelcomeView()
                }
            }
        }
    }
}

// MARK: - 프리뷰 (두 가지 상태 모두 테스트 가능)
#Preview("로그인 전 (웰컴 화면)") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
        }
}

#Preview("로그인 후 (메인 탭바)") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
}
