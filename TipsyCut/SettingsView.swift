//
//  SettingsView.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/7/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 색상 정의
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    // MARK: - 사용자 정보
    @State private var email = UserDefaults.standard.string(forKey: "userId") ?? "user@test.com"
    @State private var password = ""
    
    @State private var gender = "남성"
    @State private var birthDate = Date()
    @State private var height = "175"
    @State private var weight = "70"
    
    // MARK: - 활동량
    @State private var activityLevel = "가벼운 활동"
    
    let activityLevels = [
        "좌식 생활",
        "가벼운 활동",
        "규칙적인 운동",
        "강도 높은 운동",
        "전문 체육인"
    ]
    
    // MARK: - 목표
    @State private var goal = "유지"
    
    let goals = [
        "감량",
        "유지",
        "증량"
    ]
    
    // MARK: - 식단
    @State private var dietPreference = "일반 균형식"
    
    let dietPreferences = [
        "일반 균형식",
        "고단백",
        "키토제닉",
        "저탄고지",
        "지중해식",
        "비건채식"
    ]
    
    // MARK: - 상태
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    
    // MARK: - 부모 뷰로 칼로리 전달
    var onUpdateCalories: ((Int) -> Void)?
    
    // MARK: - 만 나이 계산
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents(
            [.year],
            from: birthDate,
            to: Date()
        )
        
        return ageComponents.year ?? 0
    }
    
    // MARK: - 권장 칼로리 계산
    var recommendedCalories: Int {
        let ageValue = Double(calculatedAge)
        let heightValue = Double(height) ?? 0
        let weightValue = Double(weight) ?? 0
        
        var bmr =
            (10.0 * weightValue)
            + (6.25 * heightValue)
            - (5.0 * ageValue)
        
        bmr += (gender == "남성") ? 5.0 : -161.0
        
        let activityMultiplier: Double
        
        switch activityLevel {
        case "좌식 생활":
            activityMultiplier = 1.2
            
        case "가벼운 활동":
            activityMultiplier = 1.375
            
        case "규칙적인 운동":
            activityMultiplier = 1.55
            
        case "강도 높은 운동":
            activityMultiplier = 1.725
            
        case "전문 체육인":
            activityMultiplier = 1.9
            
        default:
            activityMultiplier = 1.2
        }
        
        var tdee = bmr * activityMultiplier
        
        switch goal {
        case "감량":
            tdee -= 500
            
        case "증량":
            tdee += 500
            
        default:
            break
        }
        
        return (tdee > 0 && weightValue > 0)
            ? Int(tdee)
            : 0
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: 신체 정보
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "신체 정보 수정")
                        
                        HStack(spacing: 12) {
                            CustomTextField(
                                placeholder: "키 (cm)",
                                text: $height
                            )
                            
                            CustomTextField(
                                placeholder: "몸무게 (kg)",
                                text: $weight
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // MARK: 활동량 및 목표
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "활동량 및 목표 수정")
                        
                        MenuPicker(
                            title: "평소 활동량",
                            selection: $activityLevel,
                            options: activityLevels
                        )
                        
                        MenuPicker(
                            title: "나의 목표",
                            selection: $goal,
                            options: goals
                        )
                        
                        MenuPicker(
                            title: "선호하는 식단",
                            selection: $dietPreference,
                            options: dietPreferences
                        )
                    }
                    .padding(.horizontal, 4)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: 권장 칼로리
                    VStack(spacing: 8) {
                        Text("새로운 하루 권장 칼로리")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if recommendedCalories > 0 {
                            HStack(
                                alignment: .firstTextBaseline,
                                spacing: 4
                            ) {
                                Text("\(recommendedCalories)")
                                    .font(
                                        .system(
                                            size: 40,
                                            weight: .heavy,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundColor(mintColor)
                                
                                Text("kcal")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(mintColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(selectedMint)
                    .cornerRadius(20)
                    
                    // MARK: 에러 메시지
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: 저장 버튼
                    Button {
                        performUpdate()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .white)
                                )
                        } else {
                            Text("변경사항 저장")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        recommendedCalories > 0
                        ? mintColor
                        : Color.gray.opacity(0.5)
                    )
                    .cornerRadius(12)
                    .disabled(
                        recommendedCalories == 0 ||
                        isLoading
                    )
                    .padding(.top, 16)
                }
                .padding(24)
            }
            .navigationTitle("설정 및 프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarLeading
                ) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadProfile()
            }
            .alert(
                "업데이트 완료",
                isPresented: $showSuccessAlert
            ) {
                Button("확인", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("프로필 정보가 성공적으로 변경되었습니다.")
            }
        }
        .tint(mintColor)
    }
    
    // MARK: - 프로필 불러오기
    private func loadProfile() async {
        do {
            if let profile = try await NetworkManager.shared.fetchUserProfile(
                email: email
            ) {
                await MainActor.run {
                    // 키
                    self.height = String(
                        format: "%.0f",
                        profile.height
                    )
                    
                    // 몸무게
                    self.weight = String(
                        format: "%.0f",
                        profile.weight
                    )
                    
                    // 성별
                    self.gender = profile.gender
                    
                    // 활동량
                    self.activityLevel = profile.activityLevel
                    
                    // 목표
                    self.goal = profile.goal
                    
                    // 식단
                    self.dietPreference = profile.dietPreference
                    
                    // 나이를 바탕으로 생년월일 추정
                    if let approximateBirthDate =
                        Calendar.current.date(
                            byAdding: .year,
                            value: -profile.age,
                            to: Date()
                        ) {
                        self.birthDate = approximateBirthDate
                    }
                }
            }
        } catch {
            print("프로필 정보 불러오기 실패: \(error)")
        }
    }
    
    // MARK: - 프로필 업데이트
    private func performUpdate() {
        isLoading = true
        errorMessage = nil
        
        let updateData = UserSignUpData(
            email: email,
            password: password,
            gender: gender,
            age: calculatedAge,
            height: Double(height) ?? 0.0,
            weight: Double(weight) ?? 0.0,
            activityLevel: activityLevel,
            goal: goal,
            dietPreference: dietPreference,
            recommendedCalories: recommendedCalories
        )
        
        Task {
            do {
                let success =
                    try await NetworkManager.shared.updateProfile(
                        userData: updateData
                    )
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if success {
                        // 부모 뷰에 변경된 칼로리 전달
                        self.onUpdateCalories?(
                            self.recommendedCalories
                        )
                        
                        self.showSuccessAlert = true
                    } else {
                        self.errorMessage =
                            "업데이트에 실패했습니다."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    
                    self.errorMessage =
                        "네트워크 오류: \(error.localizedDescription)"
                }
            }
        }
    }
}


// MARK: - SectionTitle

private struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
}


// MARK: - CustomTextField

private struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}


// MARK: - MenuPicker

private struct MenuPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option)
                            
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selection)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}
