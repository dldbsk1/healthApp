//
//  WelcomeStartView.swift
//  TipsyCut
//
//  Created by mac16 on 9/12/26.
//

import SwiftUI

struct WelcomeStartView: View {
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 1. 상단 텍스트 영역 (옵션 2 적용)
            VStack(alignment: .leading, spacing: 10) {
                Text("환영합니다!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("마실 건 마시고, 빼볼 건 빼고")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.mintColor) // Models.swift의 mintColor 직접 참조
                
                Text("완벽한 자제보다 즐거운 관리를 지향합니다. @.@")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.subColor) // Models.swift의 subColor 직접 참조
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 40)
            
            Spacer()
            
            // MARK: - 2. 중앙 캐릭터 일러스트 (도트 찰리 캐릭터 영역)
            VStack {
                ZStack {
                    // 배경 라운드 카드
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.selectedMint) // Models.swift의 selectedMint 사용
                        .frame(width: 200, height: 200)
                    
                    // 프로젝트 Assets에 'charlie' 이미지가 등록되면 자동 적용됩니다.
                    Image("charlie")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        // Assets 등록 전 SF Symbol 기반 대체 뷰 (텍스트 제거됨)
                        .background(
                            Image(systemName: "figure.walk")
                                .font(.system(size: 70, weight: .black))
                                .foregroundColor(.mintColor)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // MARK: - 3. 하단 버튼 영역
            VStack(spacing: 12) {
                
                // 로그인하기 -> LoginView 직접 이동
                NavigationLink(destination: LoginView()) {
                    Text("로그인하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.mintColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.mintColor, lineWidth: 1.5)
                        )
                }
                
                // 회원가입하기 -> SignUpView 직접 이동
                NavigationLink(destination: SignUpView()) {
                    Text("가입하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.mintColor)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeStartView()
    }
}
