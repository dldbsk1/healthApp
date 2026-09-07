//
//  TabbarView.swift
//  TipsyCut
//
//  Created by mac00 on 6/8/26.
//

import SwiftUI

struct MainTabView: View {
    // 💡 현재 어떤 탭이 선택되었는지 관리하는 상태 변수 (초기값은 '홈')
    @State private var selectedTab: TabMenu = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. 탭별 실제 화면이 보여지는 콘텐츠 영역
            Group {
                switch selectedTab {
                case .exercise:
                    NavigationStack { ExerciseView(end_result: {})
                    }
                case .diet:
                    FoodMainView()
                case .home:
                    NavigationStack { HomeView() }
                case .alcohol:
                    NavigationStack { DrinkSelectionView()}
                case .community:
                    NavigationStack { SocialView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 85) // 👈 하단 탭 바 높이만큼 콘텐츠가 가려지지 않게 여백 지정
            
            // 2. 하단 커스텀 탭 바 UI 레이어
            customTabBar
        }
        .edgesIgnoringSafeArea(.bottom) // 탭 바가 화면 최하단단까지 꽉 차게 설정
    }
    
    // ✨ 하단 탭 바 컴포넌트 분리
    private var customTabBar: some View {
        ZStack(alignment: .top) {
            // 탭 바의 배경 흰색 사각형 (기본 베이스)
            Rectangle()
                .fill(Color.white)
                .frame(height: 90)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -4)
            
            HStack(alignment: .top, spacing: 0) {
                // 왼쪽 2개 메뉴: 운동, 식단
                TabBarButton(tab: .exercise, currentTab: $selectedTab, icon: "figure.run", title: "운동")
                TabBarButton(tab: .diet, currentTab: $selectedTab, icon: "fork.knife", title: "식단")
                
                // 🔥 중앙: 크고 동그란 홈 버튼 공간 (ZStack 오버레이 처리를 위해 빈 공간 확보 및 배치)
                centerHomeButton
                
                // 오른쪽 2개 메뉴: 술, 소통
                TabBarButton(tab: .alcohol, currentTab: $selectedTab, icon: "wineglass.fill", title: "술")
                TabBarButton(tab: .community, currentTab: $selectedTab, icon: "bubble.left.and.bubble.right.fill", title: "소통")
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    // ✨ 중앙 홈 버튼 디자인 컴포넌트
    private var centerHomeButton: some View {
        VStack {
            Button(action: {
                selectedTab = .home
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    // 홈 탭이 선택되어 있다면 파란색, 아니면 어두운 회색으로 강조
                    .background(selectedTab == .home ? Color.blue : Color(.systemGray2))
                    .clipShape(Circle())
                    .shadow(color: (selectedTab == .home ? Color.blue : Color.black).opacity(0.3), radius: 5, x: 0, y: 4)
            }
            // 탭 바 위로 살짝 튀어나오도록 마이너스 패딩(offset 효과) 주입
            .offset(y: -25)
            
            Text("홈")
                .font(.caption2)
                .fontWeight(selectedTab == .home ? .bold : .regular)
                .foregroundColor(selectedTab == .home ? .blue : .secondary)
                .offset(y: -20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 3. 일반 탭 버튼 서브 뷰
struct TabBarButton: View {
    let tab: TabMenu
    @Binding var currentTab: TabMenu
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            currentTab = tab
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.footnote)
            }
            // 선택 유무에 따른 색상 분기
            .foregroundColor(currentTab == tab ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - 4. 탭 종류를 정의해둔 열거형(Enum)
enum TabMenu {
    case exercise  // 운동
    case diet      // 식단
    case home      // 홈 (중앙)
    case alcohol   // 술
    case community // 소통
}

// MARK: - 프리뷰
#Preview {
    MainTabView()
}
