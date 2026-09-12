import SwiftUI

struct DrinkSojuView: View {
    @State private var recommendedFood: DietLog? = nil
    @State private var isLoadingPairing = true
    @State private var showSaveOptions = false
    @State private var selectedMeal = "야식"
    
    // 💡 잔 단위 주량 기록 및 칼로리 계산 (소주 1잔 = 약 50kcal)
    @State private var drinkAmount: Double = 1.0
    let sojuCupCalories: Double = 50.0
    
    var calculatedDrinkCalories: Double {
        return drinkAmount * sojuCupCalories
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 헤더 영역 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("캬~ 소주 한 잔 🍶")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("소주에는 역시 뜨끈한 국물이나\n매콤한 요리가 제격이죠! 이 안주 어때요?")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // --- 🌟 2. 잔 단위 주량 입력 슬라이더 ---
                VStack(spacing: 12) {
                    HStack {
                        Text("오늘 마신 양")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(Int(drinkAmount)) 잔")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.green)
                            Text("+\(Int(calculatedDrinkCalories)) kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Slider(value: $drinkAmount, in: 0...20, step: 1.0)
                        .tint(.green)
                    
                    HStack {
                        Text("가볍게 1잔").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("달리는 중 🏃‍♂️").font(.caption).foregroundColor(.secondary)
                    }
                    Divider()

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
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                
                // --- 3. 추천 안주 카드 영역 ---
                if isLoadingPairing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("소주와 찰떡궁합인 안주를 찾는 중...")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 300)
                } else if let food = recommendedFood {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: food.imageUrl ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 100, height: 100)
                            .cornerRadius(16)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(food.foodName)
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(2)
                                Text("\(Int(food.amount))g")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("\(Int(food.calories)) kcal")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        VStack(spacing: 12) {
                            NutritionBar(label: "탄수화물", value: food.carbs, ratio: food.carbRatio, color: .orange)
                            NutritionBar(label: "단백질", value: food.protein, ratio: food.proteinRatio, color: .red)
                            NutritionBar(label: "지방", value: food.fat, ratio: food.fatRatio, color: .purple)
                        }
                        
                        Button(action: {
                            showSaveOptions = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("식단에 기록하기")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 24)
                    
                    Button(action: {
                        fetchSojuPairing()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("다른 안주 추천받기")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if recommendedFood == nil {
                fetchSojuPairing()
            }
        }
        // 🌟 4. 분리 저장을 위한 Action Sheet
        .confirmationDialog("무엇을 식단에 기록할까요?", isPresented: $showSaveOptions, titleVisibility: .visible) {
            Button("소주만 기록하기") {
                saveLog(mode: .drinkOnly)
            }
            
            if recommendedFood != nil {
                Button("추천 안주만 기록하기") {
                    saveLog(mode: .foodOnly)
                }
                
                Button("소주 + 안주 둘 다 기록하기") {
                    saveLog(mode: .both)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("술과 안주를 따로 또는 같이 기록할 수 있습니다.")
        }
    }
    
    enum SaveMode { case drinkOnly, foodOnly, both }
    
    private func saveLog(mode: SaveMode) {
        // 💡 1. 기기에서 로그인된 유저 ID 가져오기 (테스트 중 로그인이 안 되어있을 경우를 대비해 기존 ID를 기본값으로 둡니다)
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        
        // 💡 2. 저장하는 버튼을 누른 '현재 시간'을 실시간으로 가져옵니다! (하드코딩 제거)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // 백엔드 날짜 규격과 동일
        let currentTimeString = formatter.string(from: Date())
        
        let drinkLog = DietLog(
            userId: currentUserId, // 동적 유저 ID 적용
            mealType: selectedMeal,
            foodName: "소주",
            amount: drinkAmount,
            calories: calculatedDrinkCalories,
            carbs: 0.0,
            protein: 0.0,
            fat: 0.0,
            imageUrl: "",
            eatenAt: currentTimeString // 현재 시간 적용
        )
        
        Task {
            if mode == .drinkOnly || mode == .both {
                try? await NetworkManager.shared.saveDietLog(log: drinkLog)
            }
            
            if mode == .foodOnly || mode == .both {
                if var foodLog = recommendedFood {
                    foodLog.userId = currentUserId // 안주도 현재 유저 소유로 덮어쓰기
                    foodLog.mealType = selectedMeal
                    foodLog.eatenAt = currentTimeString // 안주 먹은 시간도 지금으로 덮어쓰기
                    
                    try? await NetworkManager.shared.saveDietLog(log: foodLog)
                }
            }
        }
    }
    
    private func fetchSojuPairing() {
        Task {
            isLoadingPairing = true
            do {
                let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
                self.recommendedFood = try await NetworkManager.shared.fetchDrinkPairing(drink: "소주", userId: currentUserId)
            } catch {
                print("안주 로딩 실패: \(error)")
            }
            isLoadingPairing = false
        }
    }
}

#Preview {
    NavigationStack {
        DrinkSojuView()
    }
}
