import SwiftUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 계정 정보 상태 변수
    @State private var email = ""
    @State private var password = ""
    
    // 💡 1. 나이 텍스트 필드 대신 '생년월일(Date)' 상태 변수 추가
    @State private var gender = "남성"
    @State private var birthDate = Date()
    @State private var height = ""
    @State private var weight = ""
    
    // 추가 정보
    @State private var activityLevel = "좌식 생활"
    let activityLevels = ["좌식 생활", "가벼운 활동", "규칙적인 운동", "강도 높은 운동", "전문 체육인"]
    
    @State private var goal = "감량"
    let goals = ["감량", "유지", "증량"]
    
    @State private var dietPreference = "일반 균형식"
    let dietPreferences = ["일반 균형식", "고단백", "키토제닉", "저탄고지", "지중해식", "비건채식"]
    
    @State private var isSignUpSuccess = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // 💡 2. 생년월일을 바탕으로 '현재 만 나이'를 자동 계산하는 프로퍼티
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // 💡 3. 계산된 나이(calculatedAge)를 기초대사량 공식에 바로 적용!
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
                    HStack {
                        Button(action: {
                            dismiss() // 👈 이 코드가 이전 화면(로그인)으로 돌려보내 줍니다.
                        })
                        {
                            
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    // --- 헤더 ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("환영합니다! 👋")
                            .font(.title)
                            .bold()
                        Text("정확한 식단 및 안주 추천을 위해\n계정과 기본 정보를 입력해 주세요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    
                    // --- 계정 정보 입력 섹션 ---
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "계정 정보")
                        
                        TextField("이메일 (아이디로 사용됩니다)", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        SecureField("비밀번호", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 4)
                    
                    // --- 기본 정보 입력 섹션 ---
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "기본 정보")
                        
                        Picker("성별", selection: $gender) {
                            Text("남성").tag("남성")
                            Text("여성").tag("여성")
                        }
                        .pickerStyle(.segmented)
                        
                        // 💡 4. 생년월일을 편하게 고를 수 있는 DatePicker UI 적용
                        DatePicker("생년월일", selection: $birthDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ko_KR")) // 한국어 달력
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        HStack {
                            CustomTextField(placeholder: "키 (cm)", text: $height)
                            CustomTextField(placeholder: "몸무게 (kg)", text: $weight)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // --- 추가 정보 입력 섹션 ---
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "활동량 및 목표")
                        
                        MenuPicker(title: "평소 활동량", selection: $activityLevel, options: activityLevels)
                        MenuPicker(title: "나의 목표", selection: $goal, options: goals)
                        MenuPicker(title: "선호하는 식단", selection: $dietPreference, options: dietPreferences)
                    }
                    .padding(.horizontal, 4)
                    
                    Divider().padding(.vertical, 8)
                    
                    // --- 실시간 칼로리 계산 결과 카드 ---
                    VStack(spacing: 8) {
                        Text("하루 권장 칼로리")
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
                            Text("이제 이 칼로리에 맞춰 안주와 식단을 추천해 드릴게요!")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        } else {
                            Text("키와 몸무게를 입력하시면 계산됩니다.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(20)
                    
                    // 에러 메시지 표시
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // --- 가입 완료 버튼 ---
                    Button(action: {
                        performSignUp()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("이 정보로 시작하기")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((recommendedCalories > 0 && !email.isEmpty && !password.isEmpty) ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(recommendedCalories == 0 || email.isEmpty || password.isEmpty || isLoading)
                    .padding(.top, 16)
                    
                }
                .padding(24)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isSignUpSuccess) {
                MainTabView(userRecommendedCalories: recommendedCalories)
            }
        }
    }
    
    // --- 회원가입 통신 로직 ---
        private func performSignUp() {
            isLoading = true
            errorMessage = nil
            
            // 💡 5. 계산된 진짜 나이(calculatedAge)를 백엔드로 전송
            let userData = UserSignUpData(
                email: email,
                password: password,
                gender: gender,
                age: calculatedAge, // 여기에 자동 계산된 나이가 들어갑니다!
                height: Double(height) ?? 0.0,
                weight: Double(weight) ?? 0.0,
                activityLevel: activityLevel,
                goal: goal,
                dietPreference: dietPreference,
                recommendedCalories: recommendedCalories
            )
            
            Task {
                do {
                    let success = try await NetworkManager.shared.signUpUser(userData: userData)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if success {
                            // 🌟 새로 가입한 계정의 이메일로 기기의 저장된 아이디를 즉시 교체합니다.
                            UserDefaults.standard.set(self.email, forKey: "userId")
                            self.isSignUpSuccess = true
                        } else {
                            self.errorMessage = "회원가입에 실패했습니다. 이미 가입된 이메일이거나 서버 오류입니다."
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

// 재사용 가능한 섹션 타이틀 컴포넌트
struct SectionTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

// 재사용 가능한 커스텀 텍스트 필드
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad) // 소수점 입력이 가능하도록 변경
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
}

// 재사용 가능한 메뉴 픽커 (드롭다운 스타일)
struct MenuPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    SignUpProfileView()
}
