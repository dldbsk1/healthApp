//
//  TabbarView.swift
//  TipsyCut
//
//  Created by mac00 on 6/8/26.
//

import SwiftUI

struct MainTabView: View {
    // 현재 어떤 탭이 선택되었는지 관리하는 상태 변수 (초기값은 '홈')
    @State private var selectedTab: TabMenu = .home
    
    var body: some View {
        // 🌟 VStack(spacing: 0)으로 상단 화면 콘텐츠와 하단 탭 바 영역을 수직으로 깔끔하게 분리
        VStack(spacing: 0) {
            
            // 1. 탭별 실제 화면이 보여지는 콘텐츠 영역
            Group {
                switch selectedTab {
                case .exercise:
                    NavigationStack { ExerciseView(end_result: {}) }
                case .diet:
                    NavigationStack { FoodMainView() }
                case .home:
                    NavigationStack { HomeView() }
                case .alcohol:
                    NavigationStack { DrinkSelectionView() }
                case .community:
                    NavigationStack { SocialView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. 하단 커스텀 탭 바 UI 레이어
            customTabBar
        }
        .ignoresSafeArea(.keyboard) // 키보드가 올라올 때 탭 바가 위로 밀리는 현상 방지
    }
    
    // MARK: - 하단 커스텀 탭 바 컴포넌트
    private var customTabBar: some View {
        ZStack(alignment: .top) {
            // 탭 바의 배경 흰색 사각형 (기본 베이스)
            Rectangle()
                .fill(Color.white)
                .frame(height: 70)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -4)
            
            HStack(alignment: .top, spacing: 0) {
                // 왼쪽 2개 메뉴: 운동, 식단
                TabBarButton(tab: .exercise, currentTab: $selectedTab, icon: "figure.run", title: "운동")
                TabBarButton(tab: .diet, currentTab: $selectedTab, icon: "fork.knife", title: "식단")
                
                // 중앙: 크고 동그란 홈 버튼 공간
                centerHomeButton
                
                // 오른쪽 2개 메뉴: 술, 소통
                TabBarButton(tab: .alcohol, currentTab: $selectedTab, icon: "wineglass.fill", title: "술")
                TabBarButton(tab: .community, currentTab: $selectedTab, icon: "bubble.left.and.bubble.right.fill", title: "소통")
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }
    
    // MARK: - 중앙 홈 버튼 디자인 컴포넌트
    private var centerHomeButton: some View {
        VStack {
            Button(action: {
                selectedTab = .home
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    // 선택 여부에 따른 색상 변경
                    .background(selectedTab == .home ? Color.mintColor : Color(.systemGray3))
                    .clipShape(Circle())
                    .shadow(color: (selectedTab == .home ? Color.mintColor : Color.black).opacity(0.3), radius: 5, x: 0, y: 4)
            }
            // 탭 바 위로 살짝 튀어나오도록 마이너스 offset 적용
            .offset(y: -20)
            
            Text("홈")
                .font(.caption2)
                .fontWeight(selectedTab == .home ? .bold : .regular)
                .foregroundColor(selectedTab == .home ? .mintColor : .subColor)
                .offset(y: -16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 일반 탭 버튼 서브 뷰
struct TabBarButton: View {
    let tab: TabMenu
    @Binding var currentTab: TabMenu
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            currentTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.footnote)
            }
            .foregroundColor(currentTab == tab ? .mintColor : .subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - 탭 종류 열거형
enum TabMenu {
    case exercise  // 운동
    case diet      // 식단
    case home      // 홈 (중앙)
    case alcohol   // 술
    case community // 소통
}

// MARK: - ✨ 프리뷰 (Preview)
#Preview("MainTabView - 기본 (홈 탭)") {
    MainTabView()
}

#Preview("MainTabView - 식단 탭 테스트") {
    MainTabView()
        .onAppear {
            // 프리뷰 진입 시 식단 탭이 기본으로 선택되어 보이도록 테스트
            UserDefaults.standard.set("diet", forKey: "selectedTab")
        }
}
