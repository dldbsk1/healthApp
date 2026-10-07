//
//  LoginView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var email = ""
    @State private var password = ""
    @State private var keepLoggedIn = false
    @State private var isPasswordVisible = false

    let mintColor = Color(red: 0.40, green: 0.82, blue: 0.73)
    let subColor = Color(white: 0.45)

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                // MARK: - 로고
                VStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Text("P").font(.custom("ChalkboardSE-Bold", size: 44)).rotationEffect(.degrees(-15)).offset(y: -4)
                        Text("l").font(.custom("ChalkboardSE-Bold", size: 34)).rotationEffect(.degrees(12)).offset(y: 5)
                        Text("a").font(.custom("ChalkboardSE-Bold", size: 38)).rotationEffect(.degrees(-8)).offset(y: -2)
                        Text("n").font(.custom("ChalkboardSE-Bold", size: 36)).rotationEffect(.degrees(16)).offset(y: 4)
                        Text("B").font(.custom("ChalkboardSE-Bold", size: 48)).rotationEffect(.degrees(-12)).offset(y: -3)
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                }

                // MARK: - 입력 필드
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "envelope").foregroundColor(subColor)
                        TextField("이메일을 입력해주세요", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))

                    HStack {
                        Image(systemName: "lock").foregroundColor(subColor)
                        if isPasswordVisible {
                            TextField("비밀번호를 입력해주세요", text: $password)
                        } else {
                            SecureField("비밀번호를 입력해주세요", text: $password)
                        }
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye" : "eye.slash").foregroundColor(subColor)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
                }

                // MARK: - 로그인 상태 유지 체크박스
                HStack {
                    Button {
                        keepLoggedIn.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: keepLoggedIn ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(mintColor)
                            Text("자동 로그인")
                                .font(.subheadline)
                                .foregroundColor(keepLoggedIn ? subColor : Color(.systemGray3))
                        }
                    }
                    Spacer()
                }

                // MARK: - 로그인 버튼 (수정된 핵심 부분)
                Button(action: {
                    if keepLoggedIn {
                        // 자동로그인 체크 O: 저장소에 등록 (앱 재시작 시에도 유지)
                        isLoggedIn = true
                    } else {
                        // 자동로그인 체크 X: 일회성 세션 알림 (앱 재시작 시 웰컴뷰로 초기화)
                        NotificationCenter.default.post(name: NSNotification.Name("LoginWithoutKeep"), object: nil)
                    }
                }) {
                    Text("로그인")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(mintColor)
                        .cornerRadius(10)
                }

                // 회원가입하기
                NavigationLink(destination: SignUpView()) {
                    Text("아직 회원이 아니신가요? 회원가입하기")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .underline()
                }
            }
            .frame(maxWidth: 320)
            .padding(.horizontal, 20)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - LoginView 프리뷰
#Preview("로그인 화면") {
    NavigationStack {
        LoginView()
    }
}
