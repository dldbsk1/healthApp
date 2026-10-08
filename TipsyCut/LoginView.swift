//
//  LoginView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var keepLoggedIn = false
    @State private var isPasswordVisible = false

    let mintColor = Color(red: 0.40, green: 0.82, blue: 0.73)
    let subColor = Color(white: 0.45) // 살짝 진한 회색

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(spacing: 24) {
                    // MARK: - 취한 느낌의 구불구불 동글동글한 TipsyCut 로고
                    VStack(spacing: 8) {
                        HStack(spacing: 1) {
                            Text("T")
                                .font(.custom("ChalkboardSE-Bold", size: 40))
                                .rotationEffect(.degrees(-15))
                                .offset(y: -4)
                            
                            Text("i")
                                .font(.custom("ChalkboardSE-Bold", size: 32))
                                .rotationEffect(.degrees(12))
                                .offset(y: 5)
                            
                            Text("p")
                                .font(.custom("ChalkboardSE-Bold", size: 38))
                                .rotationEffect(.degrees(-8))
                                .offset(y: -2)
                            
                            Text("s")
                                .font(.custom("ChalkboardSE-Bold", size: 30))
                                .rotationEffect(.degrees(18))
                                .offset(y: 6)
                            
                            Text("y")
                                .font(.custom("ChalkboardSE-Bold", size: 42))
                                .rotationEffect(.degrees(-12))
                                .offset(y: -3)
                            
                            Text("C")
                                .font(.custom("ChalkboardSE-Bold", size: 46))
                                .rotationEffect(.degrees(15))
                                .offset(y: 2)
                            
                            Text("u")
                                .font(.custom("ChalkboardSE-Bold", size: 33))
                                .rotationEffect(.degrees(-16))
                                .offset(y: 4)
                            
                            Text("t")
                                .font(.custom("ChalkboardSE-Bold", size: 39))
                                .rotationEffect(.degrees(10))
                                .offset(y: -3)
                        }
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                    }

                    // MARK: - 입력 필드 (좌우 폭 단축)
                    VStack(spacing: 14) {
                        // 이메일
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(subColor)
                            TextField("이메일을 입력해주세요", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                        // 비밀번호
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(subColor)
                            if isPasswordVisible {
                                TextField("비밀번호를 입력해주세요", text: $password)
                            } else {
                                SecureField("비밀번호를 입력해주세요", text: $password)
                            }
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(subColor)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }

                    // 로그인 상태 유지
                    HStack {
                        Button {
                            keepLoggedIn.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: keepLoggedIn ? "checkmark.circle.fill" : "checkmark.circle")
                                    .foregroundColor(mintColor)
                                Text("로그인 상태 유지")
                                    .font(.subheadline)
                                    .foregroundColor(keepLoggedIn ? subColor : Color(.systemGray3))
                            }
                        }
                        Spacer()
                    }

                    // MARK: - 로그인 버튼
                    NavigationLink(destination: HomeView()) {
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
}

#Preview {
    LoginView()
}
