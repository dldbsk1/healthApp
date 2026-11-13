import SwiftUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 색상 정의 (메인 민트 테마)
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    // 계정 정보 상태 변수
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""   // 닉네임 (선택 입력)
    
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
                        
                        TextField("닉네임 (선택, 20자 이내)", text: $nickname)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .onChange(of: nickname) { newValue in
                                if newValue.count > 20 { nickname = String(newValue.prefix(20)) }
                            }
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
                        ActivityLevelGuide(selected: activityLevel)
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
                                    .foregroundColor(mintColor)
                                Text("kcal")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(mintColor)
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
                    .background(selectedMint)
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
                    .background((recommendedCalories > 0 && !email.isEmpty && !password.isEmpty) ? mintColor : Color.gray.opacity(0.5))
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
            let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
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
                recommendedCalories: recommendedCalories,
                nickname: trimmedNickname.isEmpty ? nil : trimmedNickname
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

// MARK: - 활동량 단계 설명 (활동계수 안내)
// ※ label 값은 서버/DB에 저장되고 칼로리 계산에도 쓰이므로 바꾸지 마세요. 설명 문구만 수정하면 됩니다.
struct ActivityLevelInfo {
    let label: String        // 저장되는 값 (변경 금지)
    let factor: String       // 칼로리 계산에 쓰이는 활동계수 (표시용)
    let summary: String      // 한 줄 설명
    let examples: [String]   // 구체적인 예시
    let steps: String        // 하루 평균 걸음 수 참고 (대략)
    
    static let all: [ActivityLevelInfo] = [
        ActivityLevelInfo(
            label: "좌식 생활", factor: "1.2",
            summary: "앉아서 지내는 시간이 대부분이고, 일부러 하는 운동은 거의 없어요.",
            examples: ["사무직·재택근무·학교 수업 위주의 생활",
                       "운동은 거의 하지 않고 이동은 출퇴근·통학 정도"],
            steps: "5,000보 미만"),
        ActivityLevelInfo(
            label: "가벼운 활동", factor: "1.375",
            summary: "가벼운 운동을 주 1~3회 해요.",
            examples: ["30분 걷기, 가벼운 자전거 타기",
                       "여유롭게 수영하기, 가벼운 헬스장 운동"],
            steps: "5,000~7,499보"),
        ActivityLevelInfo(
            label: "규칙적인 운동", factor: "1.55",
            summary: "중간 강도의 운동을 주 3~5회 해요.",
            examples: ["헬스장에서 짜인 루틴으로 주 4회 정도 운동",
                       "빠르게 걷기(시속 5~6km), 보통 속도 자전거, 복식 테니스를 주 3~5회"],
            steps: "7,500~9,999보"),
        ActivityLevelInfo(
            label: "강도 높은 운동", factor: "1.725",
            summary: "고강도 운동을 주 6~7회 하거나, 몸을 많이 쓰는 일을 해요.",
            examples: ["러닝·크로스핏 같은 강한 훈련을 거의 매일",
                       "건설·농업·물류 창고처럼 육체노동이 많은 직업"],
            steps: "10,000보 이상"),
        ActivityLevelInfo(
            label: "전문 체육인", factor: "1.9",
            summary: "매일 고강도 훈련에 육체노동을 더하거나, 하루 2번 훈련해요.",
            examples: ["선수·체육 전공생처럼 하루 2회 훈련",
                       "매일 강한 훈련을 하면서 몸을 많이 쓰는 직업을 병행"],
            steps: "12,500보 이상")
    ]
    
    static func find(_ label: String) -> ActivityLevelInfo? {
        all.first { $0.label == label }
    }
}

struct ActivityLevelGuide: View {
    let selected: String
    @State private var showAll = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 선택한 단계의 설명
            if let info = ActivityLevelInfo.find(selected) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(info.label)
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        Text("활동계수 ×\(info.factor)")
                            .font(.caption)
                            .foregroundColor(Color.mintColor)
                    }
                    Text(info.summary)
                        .font(.footnote)
                        .foregroundColor(.primary)
                    ForEach(info.examples, id: \.self) { example in
                        Text("• \(example)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text("하루 평균 걸음 수 참고: \(info.steps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.selectedMint)
                .cornerRadius(10)
            }
            
            // 전체 단계 비교
            DisclosureGroup(isExpanded: $showAll) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ActivityLevelInfo.all, id: \.label) { info in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(info.label)  ×\(info.factor)")
                                .font(.footnote)
                                .bold()
                            Text(info.summary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text("※ 활동계수는 널리 쓰이는 추정 방식이라 개인차가 있어요. 운동 횟수뿐 아니라 평소 생활(직업·이동)도 함께 보고, 애매하면 한 단계 낮은 쪽을 고른 뒤 체중 변화를 보며 조정하세요. 사무직이면서 고강도 운동을 매일 해도 보통은 '강도 높은 운동' 단계예요. 걸음 수는 대략적인 참고값이에요.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            } label: {
                Text("단계별 기준 한눈에 보기")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SignUpProfileView()
}
