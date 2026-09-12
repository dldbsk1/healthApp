//
//  WelcomeView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isActive = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                // MARK: - 천방지축 취한 느낌의 둥근 TipsyCut 타이틀
                VStack(spacing: 16) {
                    HStack(spacing: 1) {
                        Text("T")
                            .font(.custom("ChalkboardSE-Bold", size: 44))
                            .rotationEffect(.degrees(-15))
                            .offset(y: -4)
                        
                        Text("i")
                            .font(.custom("ChalkboardSE-Bold", size: 36))
                            .rotationEffect(.degrees(12))
                            .offset(y: 5)
                        
                        Text("p")
                            .font(.custom("ChalkboardSE-Bold", size: 42))
                            .rotationEffect(.degrees(-8))
                            .offset(y: -2)
                        
                        Text("s")
                            .font(.custom("ChalkboardSE-Bold", size: 34))
                            .rotationEffect(.degrees(18))
                            .offset(y: 6)
                        
                        Text("y")
                            .font(.custom("ChalkboardSE-Bold", size: 46))
                            .rotationEffect(.degrees(-12))
                            .offset(y: -3)
                        
                        Text("C")
                            .font(.custom("ChalkboardSE-Bold", size: 50))
                            .rotationEffect(.degrees(15))
                            .offset(y: 2)
                        
                        Text("u")
                            .font(.custom("ChalkboardSE-Bold", size: 37))
                            .rotationEffect(.degrees(-16))
                            .offset(y: 4)
                        
                        Text("t")
                            .font(.custom("ChalkboardSE-Bold", size: 43))
                            .rotationEffect(.degrees(10))
                            .offset(y: -3)
                    }
                    .foregroundColor(.black)
                    
                    Text("운동 · 식단 · 소통 · 술\n나를 위한 건강한 습관, 즐겁게 관리해요!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.subColor) // Models.swift의 subColor 사용
                        .lineSpacing(4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            // MARK: - 3초 후 WelcomeStartView로 이동
            .navigationDestination(isPresented: $isActive) {
                WelcomeStartView()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isActive = true
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
