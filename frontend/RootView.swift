//
//  RootView.swift
//  TipsyCut
//
//  Created by mac16 on 8/28/26.
//

import SwiftUI

struct RootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var isTemporaryLoggedIn: Bool = false

    var body: some View {
        Group {
            if isLoggedIn || isTemporaryLoggedIn {
                // 로그인 조건 충족 시 하단 탭 바가 포함된 메인뷰 진입
                MainTabView()
            } else {
                // 로그인 전 상태: 웰컴뷰부터 시작하는 스택
                NavigationStack {
                    WelcomeView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoginWithoutKeep"))) { _ in
            isTemporaryLoggedIn = true
        }
    }
}

// MARK: - RootView 프리뷰
#Preview("1. 로그인 전 (웰컴 화면 시작)") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
        }
}

#Preview("2. 자동 로그인 후 (메인 탭바)") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
}
