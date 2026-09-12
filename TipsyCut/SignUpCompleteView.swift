//
//  SignUpCompleteView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct SignUpCompleteView: View {

    let mintColor = Color.mintColor
    let lightMint = Color.lightMint
    let subColor = Color.subColor

    var body: some View {

        VStack {

            
            // 진행바
            VStack(spacing: 12) {

                Text("가입 완료")
                    .font(.headline)

                GeometryReader { geo in

                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(lightMint)
                            .frame(height: 6)

                        Capsule()
                            .fill(mintColor)
                            .frame(width: geo.size.width, height: 6)

                    }

                }
                .frame(height: 6)

            }
            .padding(.horizontal)
            .padding(.top, 10)
            

            Spacer()

            // 체크 아이콘 + 컨페티
            ZStack {

                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .offset(x: -70, y: -70)

                Circle()
                    .fill(mintColor)
                    .frame(width: 6, height: 6)
                    .offset(x: 65, y: -60)

                Circle()
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .offset(x: 45, y: -82)

                Circle()
                    .fill(Color.cyan.opacity(0.8))
                    .frame(width: 5, height: 5)
                    .offset(x: -55, y: -95)

                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .offset(x: -58, y: 48)

                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(mintColor)
                    .offset(x: 72, y: 42)

                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundColor(.orange)
                    .offset(x: -82, y: 10)

                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundColor(.mint)
                    .offset(x: 82, y: 0)

                // 체크 원
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [lightMint, mintColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(
                        color: mintColor.opacity(0.25),
                        radius: 20,
                        x: 0,
                        y: 10
                    )

                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)

            }
            .padding(.bottom, 45)

            Text("회원가입을 축하합니다!")
                .font(.title2)
                .fontWeight(.bold)

            Text("이제 TipsyCut과 함께\n건강한 습관을 만들어봐요")
                .font(.subheadline)
                .foregroundColor(subColor)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
            
            Spacer()

            NavigationLink(destination: LoginView()) {

                Text("시작하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(mintColor)
                    .cornerRadius(10)

            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)

    }
}

#Preview {
    NavigationStack {
        SignUpCompleteView()
    }
}
