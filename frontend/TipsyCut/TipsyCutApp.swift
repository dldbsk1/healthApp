//
//  TipsyCutApp.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//

import SwiftUI

@main
struct TipsyCutApp: App {
    
    // 앱 전체에서 공유해서 사용할 SocialViewModel
    @StateObject private var socialViewModel = SocialViewModel()
    
    init() {
        // 로그인 없이 항상 같은 사용자로 동작
        UserDefaults.standard.set(AppConfig.fixedUserId, forKey: "userId")
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(socialViewModel)
        }
    }
}
