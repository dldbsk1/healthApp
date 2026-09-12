import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 임시로 UserDefaults나 로그인 세션에서 가져올 사용자 이메일 (실제 환경에 맞게 수정)
    @State private var email = UserDefaults.standard.string(forKey: "userId") ?? "user@test.com"
    @State private var password = "" // 업데이트 폼이라 비밀번호는 빈값으로 처리하거나 제외
    
    // 💡 초기값은 서버에서 받아오거나 기존 값을 넣어줍니다. (여기선 회원가입과 동일한 구조 유지)
    @State private var gender = "남성"
    @State private var birthDate = Date()
    @State private var height = "175"
    @State private var weight = "70" // 👈 변경 포인트!
    
    @State private var activityLevel = "가벼운 활동"
    let activityLevels = ["좌식 생활", "가벼운 활동", "규칙적인 운동", "강도 높은 운동", "전문 체육인"]
    
    @State private var goal = "유지" // 👈 변경 포인트!
    let goals = ["감량", "유지", "증량"]
    
    @State private var dietPreference = "일반 균형식"
    let dietPreferences = ["일반 균형식", "고단백", "키토제닉", "저탄고지", "지중해식", "비건채식"]
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    
    // 부모 뷰(MainTabView)로 변경된 칼로리를 올려보내기 위한 클로저
    var onUpdateCalories: ((Int) -> Void)?
    
    // 생년월일을 바탕으로 한 만 나이 계산[cite: 8]
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // 입력값 변경 시 실시간으로 변하는 권장 칼로리 계산 로직 (회원가입과 동일)[cite: 8]
    var recommendedCalories: Int {
        let ageValue = Double(calculatedAge)
        let heightValue = Double(height) ?? 0
        let weightValue = Double(weight) ?? 0
        
        var bmr = (10.0 * weightValue) + (6.25 * heightValue) - (5.0 * ageValue)
        bmr += (gender == "남성") ? 5.0 : -161.0
        
        let activityMultiplier: Double
        switch activityLevel {
        case "좌식 생활": activityMultiplier = 1.2
        case "가벼운 활동": activityMultiplier = 1.375
        case "규칙적인 운동": activityMultiplier = 1.55
        case "강도 높은 운동": activityMultiplier = 1.725
        case "전문 체육인": activityMultiplier = 1.9
        default: activityMultiplier = 1.2
        }
        
        var tdee = bmr * activityMultiplier
        
        switch goal {
        case "감량": tdee -= 500
        case "증량": tdee += 500
        default: break
        }
        
        return (tdee > 0 && weightValue > 0) ? Int(tdee) : 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // --- 수정 정보 입력 섹션 ---
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "신체 정보 수정")
                        
                        HStack {
                            CustomTextField(placeholder: "키 (cm)", text: $height)
                            CustomTextField(placeholder: "몸무게 (kg)", text: $weight)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "활동량 및 목표 수정")
                        
                        MenuPicker(title: "평소 활동량", selection: $activityLevel, options: activityLevels)
                        MenuPicker(title: "나의 목표", selection: $goal, options: goals)
                        MenuPicker(title: "선호하는 식단", selection: $dietPreference, options: dietPreferences)
                    }
                    .padding(.horizontal, 4)
                    
                    Divider().padding(.vertical, 8)
                    
                    // --- 실시간 칼로리 계산 결과 카드 ---
                    VStack(spacing: 8) {
                        Text("새로운 하루 권장 칼로리")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if recommendedCalories > 0 {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(recommendedCalories)")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("kcal")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(20)
                    
                    // 에러 메시지
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // --- 저장 버튼 ---
                    Button(action: {
                        performUpdate()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("변경사항 저장")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((recommendedCalories > 0) ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(recommendedCalories == 0 || isLoading)
                    .padding(.top, 16)
                }
                .padding(24)
            }
            .navigationTitle("설정 및 프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            // 업데이트 완료 알림창
            .alert("업데이트 완료", isPresented: $showSuccessAlert) {
                Button("확인", role: .cancel) { dismiss() }
            } message: {
                Text("프로필 정보가 성공적으로 변경되었습니다.")
            }
        }
        .navigationTitle("설정 및 프로필")
                    .navigationBarTitleDisplayMode(.inline)
                    // 💡 화면이 켜질 때 백엔드에서 내 정보를 가져와서 덮어씌웁니다.
                    .task {
                        do {
                            if let profile = try await NetworkManager.shared.fetchUserProfile(email: email) {
                                DispatchQueue.main.async {
                                    // 소수점 제거 후 문자열로 변환하여 텍스트 필드에 삽입
                                    self.height = String(format: "%.0f", profile.height)
                                    self.weight = String(format: "%.0f", profile.weight)
                                    self.gender = profile.gender
                                    self.activityLevel = profile.activityLevel
                                    self.goal = profile.goal
                                    self.dietPreference = profile.dietPreference
                                    
                                    // 나이(Int)를 바탕으로 DatePicker용 생년월일 역산
                                    if let approximateBirthDate = Calendar.current.date(byAdding: .year, value: -profile.age, to: Date()) {
                                        self.birthDate = approximateBirthDate
                                    }
                                }
                            }
                        } catch {
                            print("프로필 정보 불러오기 실패: \(error)")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("닫기") { dismiss() }
                        }
                    }
    }
    
    // --- 정보 업데이트 통신 로직 ---
    private func performUpdate() {
        isLoading = true
        errorMessage = nil
        
        let updateData = UserSignUpData(
            email: email,
            password: password, // 백엔드 처리 방식에 따라 다름
            gender: gender,
            age: calculatedAge,
            height: Double(height) ?? 0.0,
            weight: Double(weight) ?? 0.0,
            activityLevel: activityLevel,
            goal: goal,
            dietPreference: dietPreference,
            recommendedCalories: recommendedCalories // 새로 계산된 칼로리
        )
        
        Task {
            do {
                let success = try await NetworkManager.shared.updateProfile(userData: updateData)
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        // 💡 성공 시, 콜백을 통해 부모 뷰(MainTabView)에 변경된 칼로리 전달!
                        self.onUpdateCalories?(self.recommendedCalories)
                        self.showSuccessAlert = true
                    } else {
                        self.errorMessage = "업데이트에 실패했습니다."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "네트워크 오류: \(error.localizedDescription)"
                }
            }
        }
    }
}
