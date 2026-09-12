import SwiftUI

struct DrinkWhiskeyView: View {
    
    let singleMalts = ["Whiskey1", "Whiskey2", "Whiskey3"]
    let blendedWhiskeys = ["Whiskey4", "Whiskey5", "Whiskey6"]
    let bourbons = ["Whiskey7", "Whiskey8", "Whiskey9"]
    
    @State private var selectedWhiskeyLog: DietLog? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- 상단 헤더 영역 ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("위스키")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.init(white: 0.2))
                        
                        Text("의 풍미를 살려줄 안주 🥃")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    HStack {
                        Text("취향에 맞는 위스키를 골라보세요!")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // --- 세로 스크롤뷰 영역 ---
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        whiskeySection(title: "싱글 몰트 위스키", images: singleMalts)
                        whiskeySection(title: "블렌디드 위스키", images: blendedWhiskeys)
                        whiskeySection(title: "버번 위스키", images: bourbons)
                    }
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .sheet(item: $selectedWhiskeyLog) { whiskey in
            WhiskeyDetailSheet(whiskey: whiskey)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // --- 가로 캐러셀 뷰 빌더 함수 ---
    @ViewBuilder
    private func whiskeySection(title: String, images: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(images, id: \.self) { imageName in
                        let whiskeyData = getWhiskeyData(for: imageName)
                        let isSelected = selectedWhiskeyLog?.foodName == whiskeyData.foodName
                        
                        VStack(spacing: 12) {
                            Image(whiskeyData.imageUrl ?? imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 150)
                                .cornerRadius(8)
                            
                            Text(whiskeyData.foodName)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .frame(width: 140)
                        .background(isSelected ? Color.indigo.opacity(0.1) : Color(.systemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWhiskeyLog = whiskeyData
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
    }
    
    func getWhiskeyData(for whiskeyId: String) -> DietLog {
        // 💡 껍데기를 만들 때도 기기의 유저 ID와 현재 시간을 넣도록 수정!
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
                
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        switch whiskeyId {
                case "Whiskey1": return DietLog(userId: currentUserId, mealType: "간식", foodName: "글렌피딕", amount: 1.0, calories: 70, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey1", eatenAt: currentTimeString)
                case "Whiskey2": return DietLog(userId: currentUserId, mealType: "간식", foodName: "맥캘란", amount: 1.0, calories: 70, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey2", eatenAt: currentTimeString)
                case "Whiskey3": return DietLog(userId: currentUserId, mealType: "간식", foodName: "발베니", amount: 1.0, calories: 70, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey3", eatenAt: currentTimeString)
                
                case "Whiskey4": return DietLog(userId: currentUserId, mealType: "간식", foodName: "조니워커", amount: 1.0, calories: 65, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey4", eatenAt: currentTimeString)
                case "Whiskey5": return DietLog(userId: currentUserId, mealType: "간식", foodName: "발렌타인", amount: 1.0, calories: 65, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey5", eatenAt: currentTimeString)
                case "Whiskey6": return DietLog(userId: currentUserId, mealType: "간식", foodName: "시바스 리갈", amount: 1.0, calories: 65, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey6", eatenAt: currentTimeString)
                
                case "Whiskey7": return DietLog(userId: currentUserId, mealType: "간식", foodName: "짐빔", amount: 1.0, calories: 75, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey7", eatenAt: currentTimeString)
                case "Whiskey8": return DietLog(userId: currentUserId, mealType: "간식", foodName: "메이커스 마크", amount: 1.0, calories: 75, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey8", eatenAt: currentTimeString)
                default: return DietLog(userId: currentUserId, mealType: "간식", foodName: "와일드 터키", amount: 1.0, calories: 80, carbs: 0, protein: 0, fat: 0, imageUrl: "Whiskey9", eatenAt: currentTimeString)
                }
    }
}

// --- 하단 시트 뷰 상세 구성 ---
struct WhiskeyDetailSheet: View {
    let whiskey: DietLog
    
    @Environment(\.dismiss) private var dismiss
    
    // 💡 분리 기록을 위한 Action Sheet 상태 변수
    @State private var showSaveOptions = false
    
    // 💡 기본값은 야식이지만, 유저가 자유롭게 바꿀 수 있도록 Picker 제공
    @State private var selectedMeal = "야식"
    
    @State private var recommendedFood: DietLog? = nil
    @State private var isLoadingPairing = true
    
    // 💡 잔 단위 주량 기록 및 칼로리 계산 (위스키 1잔 = 약 30ml)
    @State private var drinkAmount: Double = 1.0
    var calculatedDrinkCalories: Double {
        return drinkAmount * whiskey.calories
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 위스키 이미지
                HStack {
                    Spacer()
                    Image(whiskey.imageUrl ?? "Whiskey1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 220)
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // --- 🌟 주량 입력 및 식사 시간 선택 영역 ---
                VStack(spacing: 16) {
                    // 주량 조절 슬라이더
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(whiskey.foodName)
                                    .font(.title2).bold()
                                Text("오늘 마신 양")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(drinkAmount)) 잔 (30ml)")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.indigo)
                                Text("+\(Int(calculatedDrinkCalories)) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Slider(value: $drinkAmount, in: 0...10, step: 1.0)
                            .tint(.indigo)
                    }
                    
                    Divider()
                    
                    // 💡 식사 시간 분류 Picker 추가
                    HStack {
                        Text("식사 분류")
                            .font(.system(size: 16, weight: .bold))
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
                        .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Divider()
                
                // --- 추천 푸드 가이드 영역 ---
                VStack(alignment: .leading, spacing: 18) {
                    Text("✨ 페어링 추천 메뉴")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.indigo)
                    
                    if isLoadingPairing {
                        ProgressView("최고의 안주를 찾는 중...")
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if let food = recommendedFood {
                        
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: food.imageUrl ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(food.foodName)
                                    .font(.system(size: 16, weight: .bold))
                                Text("\(Int(food.amount))g")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("\(Int(food.calories)) kcal")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.indigo)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        VStack(spacing: 10) {
                            NutritionBar(label: "탄수화물", value: food.carbs, ratio: food.carbRatio, color: .orange)
                            NutritionBar(label: "단백질", value: food.protein, ratio: food.proteinRatio, color: .red)
                            NutritionBar(label: "지방", value: food.fat, ratio: food.fatRatio, color: .purple)
                        }
                        .padding(.horizontal, 4)
                        
                        // 🌟 통합 액션 버튼
                        Button(action: {
                            showSaveOptions = true // 버튼 누르면 선택 창 띄우기
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("식단에 기록하기")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.indigo)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                isLoadingPairing = true
                do {
                    let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
                    self.recommendedFood = try await NetworkManager.shared.fetchDrinkPairing(drink: whiskey.foodName, userId: currentUserId)
                } catch {
                    print("안주 로딩 실패: \(error)")
                }
                isLoadingPairing = false
            }
        }
        // 🌟 분리 저장을 위한 Action Sheet (Confirmation Dialog)
        .confirmationDialog("무엇을 식단에 기록할까요?", isPresented: $showSaveOptions, titleVisibility: .visible) {
            
            Button("위스키만 기록하기") {
                saveLog(mode: .drinkOnly)
            }
            
            if recommendedFood != nil {
                Button("추천 안주만 기록하기") {
                    saveLog(mode: .foodOnly)
                }
                
                Button("위스키 + 안주 둘 다 기록하기") {
                    saveLog(mode: .both)
                }
            }
            
            Button("취소", role: .cancel) { }
        } message: {
            Text("술과 안주를 따로 또는 같이 기록할 수 있습니다.")
        }
    }
    
    // 💡 선택한 옵션에 따라 분리해서 저장하는 헬퍼 함수
    enum SaveMode { case drinkOnly, foodOnly, both }
    
    private func saveLog(mode: SaveMode) {
        // 1. 기기에서 로그인된 유저 ID 가져오기
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        
        // 2. 실시간 현재 시간 구하기
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        let drinkLog = DietLog(
            userId: currentUserId,
            mealType: selectedMeal, // 💡 사용자가 선택한 식사 시간이 적용됩니다.
            foodName: whiskey.foodName,
            amount: drinkAmount,
            calories: calculatedDrinkCalories,
            carbs: whiskey.carbs,
            protein: whiskey.protein,
            fat: whiskey.fat,
            imageUrl: whiskey.imageUrl,
            eatenAt: currentTimeString
        )
        
        Task {
            if mode == .drinkOnly || mode == .both {
                try? await NetworkManager.shared.saveDietLog(log: drinkLog)
            }
            
            if mode == .foodOnly || mode == .both {
                if var foodLog = recommendedFood {
                    foodLog.userId = currentUserId
                    foodLog.mealType = selectedMeal // 💡 안주에도 동일하게 적용
                    foodLog.eatenAt = currentTimeString
                    try? await NetworkManager.shared.saveDietLog(log: foodLog)
                }
            }
            dismiss() // 저장 후 시트 닫기
        }
    }
}

#Preview {
    DrinkWhiskeyView()
}
