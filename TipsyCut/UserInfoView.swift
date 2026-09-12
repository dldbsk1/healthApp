//
//  UserInfoView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI
import PhotosUI

struct UserInfoView: View {

    @State private var name = ""
    @State private var gender = ""
    @State private var age = ""
    @State private var height = "170"
    @State private var weight = "60"
    @State private var activityLevel = "보통 (주 3~4회 운동)"

    // 프로필 사진
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    let mintColor = Color.mintColor
    let lightMint = Color(red: 0.75, green: 0.92, blue: 0.87)
    let selectedMint = Color(red: 0.90, green: 0.98, blue: 0.95)
    let subColor = Color(white: 0.45)

    // 여성, 남성 2가지 항목
    let genderOptions = ["여성", "남성"]
    
    let activityOptions = [
        "적음 (거의 안 함)",
        "보통 (주 3~4회 운동)",
        "많음 (주 5회 이상)"
    ]

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // 상단 제목 + 진행바 (상단 여백 제거)
                VStack(spacing: 12) {

                    Text("사용자 정보 입력")
                        .font(.headline)

                    GeometryReader { geo in

                        ZStack(alignment: .leading) {

                            Capsule()
                                .fill(lightMint)
                                .frame(height: 6)

                            Capsule()
                                .fill(mintColor)
                                .frame(width: geo.size.width * 0.5, height: 6)
                        }

                    }
                    .frame(height: 6)
                }
                .padding(.top, 0) // 👈 상단 패딩 제거
                
                // 프로필 사진
                VStack(spacing: 8) {

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {

                        ZStack {

                            Circle()
                                .fill(lightMint.opacity(0.35))
                                .frame(width: 90, height: 90)

                            if let profileImage {

                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())

                            } else {

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(mintColor)

                            }

                        }

                    }
                    .onChange(of: selectedItem) { _, newItem in

                        Task {

                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {

                                profileImage = image

                            }

                        }

                    }

                    Text("프로필 사진을\n등록해주세요")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(subColor)

                }

                // 이름
                HStack(spacing: 12) {

                    Image(systemName: "person")
                        .foregroundColor(subColor)

                    TextField("이름을 입력해주세요", text: $name)

                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // 성별 (여성 / 남성)
                VStack(alignment: .leading, spacing: 8) {

                    Text("성별")
                        .bold()

                    HStack(spacing: 12) {

                        ForEach(genderOptions, id: \.self) { option in

                            Button {

                                gender = option

                            } label: {

                                Text(option)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        gender == option
                                        ? selectedMint
                                        : Color(.systemGray6)
                                    )
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                gender == option
                                                ? mintColor
                                                : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                    .cornerRadius(10)

                            }

                        }

                    }

                }

                // 신체 정보
                VStack(alignment: .leading, spacing: 14) {

                    Text("신체 정보")
                        .bold()

                    // 나이
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(subColor)

                        Spacer()

                        TextField("25", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)

                        Text("세")
                            .foregroundColor(subColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // 키
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(subColor)

                        Spacer()

                        TextField("170", text: $height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)

                        Text("cm")
                            .foregroundColor(subColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // 몸무게
                    HStack(spacing: 12) {

                        Image(systemName: "scalemass")
                            .foregroundColor(subColor)
                        
                        Spacer()
        
                        TextField("60", text: $weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)

                        Text("kg")
                            .foregroundColor(subColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                }

                // 활동 수준
                VStack(alignment: .leading, spacing: 8) {

                    Text("활동 수준")
                        .bold()

                    HStack(spacing: 12) {

                        Image(systemName: "figure.walk")
                            .foregroundColor(subColor)

                        Picker("", selection: $activityLevel) {

                            ForEach(activityOptions, id: \.self) { option in

                                Text(option)
                                    .tag(option)

                            }

                        }
                        .pickerStyle(.menu)
                        .tint(.black)

                        Spacer()

                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                }

                NavigationLink(destination: GoalSettingView()) {

                    Text("다음")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(mintColor)
                        .cornerRadius(10)

                }

            }
            .padding(.horizontal)
            .padding(.top, 0) // 👈 ScrollView 전체의 상단 패딩을 0으로 수정
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar) // 👈 NavigationStack 기본 상단바 숨김 (필요시)
    }

}

#Preview {

    NavigationStack {

        UserInfoView()

    }

}
