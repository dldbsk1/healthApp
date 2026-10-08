//
//  SignUpView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var nickname = ""
    @State private var isPasswordVisible = false

    let mintColor = Color.mintColor
    let lightMint = Color.lightMint
    let subColor = Color.subColor
    
    var body: some View {

        VStack(spacing: 24) {

            // 상단 제목 + 진행바
            VStack(spacing: 12) {

                Text("회원가입")
                    .font(.headline)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(lightMint)
                            .frame(height: 6)

                        Capsule()
                            .fill(mintColor)
                            .frame(width: geo.size.width * 0.25, height: 6)   // 1/4

                    }
                }
                .frame(height: 6)

            }
            .padding(.top,10)

            Text("계정 정보를 입력해주세요")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 80)

            VStack(spacing: 14) {

                // 이메일
                HStack(spacing: 12) {

                    Image(systemName: "envelope")
                        .foregroundColor(subColor)

                    TextField("이메일을 입력해주세요", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // 비밀번호
                HStack(spacing: 12) {

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
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // 비밀번호 확인
                HStack(spacing: 12) {

                    Image(systemName: "lock")
                        .foregroundColor(subColor)

                    SecureField("비밀번호 확인", text: $passwordConfirm)

                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // 닉네임
                VStack(spacing: 4) {

                    HStack(spacing: 12) {

                        Image(systemName: "at")
                            .foregroundColor(subColor)

                        TextField("닉네임을 입력해주세요", text: $nickname)

                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Text("2~12자 이하")
                        .font(.caption)
                        .foregroundColor(subColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                }

            }
            .padding(.horizontal)
            //.padding(.top, 10)
            
            // 다음 버튼
            NavigationLink(destination: UserInfoView()) {

                Text("다음")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(mintColor)
                    .cornerRadius(10)

            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()

        }
        .padding(.horizontal)

    }

}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
