import SwiftUI

struct FoodSaveView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showCamera: Bool
    @Binding var path: NavigationPath
    
    let defaultName: String
    let defaultWeight: String
    let calories: Double // 💡 AI가 계산한 칼로리를 저장할 변수
    
    // 💡 [추가] 서버가 "숟가락 미인식 -> 기본값 추정"일 때 보내는 안내 문구.
    // 정상적으로 정밀 계산된 경우엔 nil이라 배너가 표시되지 않음.
    let needsSpoonMessage: String?
    
    // 💡 [추가] 저장 완료 시 메인 화면의 식단 목록을 갱신하도록 알리는 콜백
    let onSaveComplete: () -> Void

    @State private var foodName: String
    @State private var foodWeight: String
    
    // 💡 식사 종류를 선택할 수 있도록 상태 변수 추가
    @State private var selectedMeal = "점심"
    
    init(showCamera: Binding<Bool>, path: Binding<NavigationPath>, foodName: String, foodWeight: String, calories: Double, needsSpoonMessage: String? = nil, onSaveComplete: @escaping () -> Void = {}) {
        self._showCamera = showCamera
        self._path = path
        self.defaultName = foodName
        self.defaultWeight = foodWeight
        self.calories = calories
        self.needsSpoonMessage = needsSpoonMessage
        self.onSaveComplete = onSaveComplete
        
        _foodName = State(initialValue: foodName)
        _foodWeight = State(initialValue: foodWeight)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 1. 상단 타이틀
            VStack(spacing: 8) {
                Text("음식 정보 확인")
                    .font(.title2.bold())
                Text("AI가 분석한 결과가 맞는지 확인해 주세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // 💡 [추가] 숟가락 미인식 -> 기본값 추정이었을 때만 노출되는 경고 배너
            if let message = needsSpoonMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // 2. 상단 중심: 음식 사진
            Image("unnamed")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // 3. 중앙: AI 제공 정보 및 수정 영역
            VStack(spacing: 20) {
                HStack {
                    Text("인식된 음식")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(foodName)
                        .font(.title3.bold())
                }
                .padding(.horizontal, 10)
                
                Divider()
                
                // 중량(g) 수정 입력창
                HStack {
                    Text("추정 중량")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        TextField("250", text: $foodWeight)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("g")
                            .font(.title3.bold())
                    }
                }
                .padding(.horizontal, 10)
                
                Divider()
                
                // AI가 추정한 칼로리 실시간 표시
                HStack {
                    Text("추정 칼로리")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(calories)) kcal")
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                
                Divider()
                
                // 💡 [추가] 식사 분류 선택기
                HStack {
                    Text("식사 분류")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("식사 분류", selection: $selectedMeal) {
                        Text("아침").tag("아침")
                        Text("점심").tag("점심")
                        Text("저녁").tag("저녁")
                        Text("간식").tag("간식")
                        Text("야식").tag("야식")
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .font(.title3.bold())
                }
                .padding(.horizontal, 10)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 4. 하단 버튼 영역
            HStack(spacing: 15) {
                // 다시 찍기 버튼
                Button(action: {
                    dismiss()
                }) {
                    Text("다시 찍기")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // 저장하기 버튼
                Button(action: {
                    let finalWeight = Double(foodWeight) ?? (Double(defaultWeight) ?? 0.0)
                    let originalWeight = Double(defaultWeight) ?? 1.0
                    let weightRatio = originalWeight > 0 ? (finalWeight / originalWeight) : 1.0
                    let adjustedCalories = calories * weightRatio
                    
                    // 💡 실제 아이디 및 현재 시간 추출
                    let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    let currentTimeString = formatter.string(from: Date())
                    
                    // 💡 AI 실측값을 베이스로 인스턴스 조립
                    let newLog = DietLog(
                        userId: currentUserId,
                        mealType: selectedMeal, // 💡 선택한 식사 분류(아침/점심/저녁/간식/야식) 동적 적용
                        foodName: foodName,
                        amount: finalWeight,
                        calories: adjustedCalories,
                        carbs: 30.0 * weightRatio,
                        protein: 20.0 * weightRatio,
                        fat: 5.0 * weightRatio,
                        imageUrl: "unnamed",
                        eatenAt: currentTimeString
                    )
                    
                    Task {
                        do {
                            try await NetworkManager.shared.saveDietLog(log: newLog)
                            // 🌟 저장이 완료되면 메인 화면의 목록을 갱신하고, 카메라 모달 전체를 완전 종료
                            await MainActor.run {
                                onSaveComplete()
                                showCamera = false
                            }
                        } catch {
                            print("❌ MongoDB 저장 실패: \(error)")
                        }
                    }
                }) {
                    Text("저장하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
