import SwiftUI

// 술 화면 공통 뷰
// - 병 그림을 세로로 드래그해 "한 병 기준으로 얼마나 마셨는지" 입력
// - 칼로리는 주류 표의 1병 칼로리 × 마신 병 수로 계산
// - 종류가 여러 개(예: 와인 적/백/샴페인)면 선택 버튼이 나타남
struct DrinkBottleView: View {
    let title: String
    let subtitle: String
    let loadingText: String
    let variants: [DrinkSpec]
    
    // MARK: - 색상 정의 (메인 민트 테마)
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    // 탄·단·지 색상
    let carbColor = Color(red: 0.98, green: 0.85, blue: 0.60)        // 탄수화물
    let proteinColor = Color(red: 0.98, green: 0.50, blue: 0.55)     // 단백질
    let fatColor = Color(red: 1.00, green: 0.88, blue: 0.35)         // 지방
    
    @State private var selectedIndex = 0
    @State private var partialFill: Double = 0.0     // 지금 병에서 마신 비율 (0 ~ 1)
    @State private var fullBottles: Int = 0          // 다 비운 병 수
    @State private var selectedMeal = "야식"
    @State private var showSaveOptions = false
    
    @State private var recommendedFood: DietLog? = nil
    @State private var isLoadingPairing = true
    @State private var foodServings: Double = 1.0    // 안주 섭취량(인분)
    
    private var spec: DrinkSpec { variants[selectedIndex] }
    private var scaledFood: DietLog? { recommendedFood?.scaled(by: foodServings) }
    
    // 마신 총 병 수 (소수 둘째 자리까지)
    private var totalBottles: Double {
        ((Double(fullBottles) + partialFill) * 100).rounded() / 100
    }
    private var drinkCalories: Double {
        (totalBottles * spec.bottleKcal).rounded()
    }
    // 잔(컵) 환산 문구 — 하이볼처럼 잔 기준이 없으면 nil
    private var cupsLine: String? {
        guard let cupCC = spec.cupCC, let cupName = spec.cupName else { return nil }
        let cups = String(format: "%.1f", totalBottles * spec.bottleCC / cupCC)
        return "약 \(cups)\(cupName) (\(Int(cupCC))cc 기준)"
    }
    
    // 용량·칼로리·도수 안내 문구
    private var specCaption: String {
        var text = "1\(spec.containerName) \(Int(spec.bottleCC))cc · \(Int(spec.bottleKcal))kcal"
        if let abv = spec.abv {
            text += " · 알코올 \(abv)%"
        }
        return text
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                intakeSection
                pairingSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        // 화면이 열릴 때, 그리고 종류(적/백/샴페인 등)를 바꿀 때마다 안주를 새로 추천받음
        .task(id: selectedIndex) {
            await fetchPairing()
        }
        .confirmationDialog("무엇을 식단에 기록할까요?", isPresented: $showSaveOptions, titleVisibility: .visible) {
            if totalBottles > 0 {
                Button("\(spec.logName)만 기록하기") {
                    saveLog(mode: .drinkOnly)
                }
            }
            
            if recommendedFood != nil {
                Button("추천 안주만 기록하기") {
                    saveLog(mode: .foodOnly)
                }
                
                if totalBottles > 0 {
                    Button("\(spec.logName) + 안주 둘 다 기록하기") {
                        saveLog(mode: .both)
                    }
                }
            }
            
            Button("취소", role: .cancel) { }
        } message: {
            Text("술과 안주를 따로 또는 같이 기록할 수 있습니다.")
        }
    }
    
    // MARK: - 1. 상단 헤더
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    // MARK: - 2. 마신 양 (병 채우기) + 식사 분류
    private var intakeSection: some View {
        VStack(spacing: 16) {
            
            // 종류 선택 버튼 (종류가 2개 이상일 때만)
            if variants.count > 1 {
                HStack(spacing: 10) {
                    ForEach(variants.indices, id: \.self) { i in
                        Button(action: {
                            selectedIndex = i
                        }) {
                            Text(variants[i].label)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedIndex == i ? selectedMint : Color(.systemGray6))
                                .foregroundColor(selectedIndex == i ? mintColor : .primary)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedIndex == i ? mintColor : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    Spacer()
                }
            }
            
            HStack(alignment: .center, spacing: 16) {
                // 세로 병 — 위아래로 드래그해서 채우기
                BottleFillView(
                    fraction: $partialFill,
                    style: spec.style,
                    glassColor: spec.glassColor,
                    liquidColor: spec.liquidColor
                )
                .frame(width: 120, height: spec.style.displayHeight)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("오늘 마신 양")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("\(formatBottleCount(totalBottles))\(spec.containerName)")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(mintColor)
                    
                    if let cupsLine = cupsLine {
                        Text(cupsLine)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("+\(Int(drinkCalories)) kcal")
                        .font(.system(size: 16, weight: .bold))
                    
                    // 빠른 선택
                    HStack(spacing: 6) {
                        quickFillButton(label: "¼", value: 0.25)
                        quickFillButton(label: "½", value: 0.5)
                        quickFillButton(label: "¾", value: 0.75)
                        quickFillButton(label: "가득", value: 1.0)
                    }
                    
                    // 다 비운 병 수
                    HStack(spacing: 8) {
                        Text("다 비운 \(spec.containerName)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            if fullBottles > 0 { fullBottles -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(fullBottles > 0 ? mintColor : Color.gray.opacity(0.4))
                        }
                        Text("\(fullBottles)")
                            .font(.system(size: 15, weight: .bold))
                            .frame(minWidth: 18)
                        Button(action: {
                            if fullBottles < 10 { fullBottles += 1 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(fullBottles < 10 ? mintColor : Color.gray.opacity(0.4))
                        }
                    }
                    
                    Text(specCaption)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        partialFill = 0
                        fullBottles = 0
                    }) {
                        Text("초기화")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .underline()
                    }
                }
            }
            
            Divider()
            
            // 식사 시간 분류
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
    }
    
    private func quickFillButton(label: String, value: Double) -> some View {
        Button(action: {
            partialFill = value
        }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(partialFill == value ? selectedMint : Color(.systemGray6))
                .foregroundColor(partialFill == value ? mintColor : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(partialFill == value ? mintColor : Color.clear, lineWidth: 1)
                )
        }
    }
    
    // MARK: - 3. 추천 안주
    @ViewBuilder
    private var pairingSection: some View {
        if isLoadingPairing {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(loadingText)
                    .foregroundColor(.secondary)
            }
            .frame(height: 300)
        } else if let food = scaledFood {
            foodCard(food)
            
            Button(action: {
                Task { await fetchPairing() }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("다른 안주 추천받기")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(mintColor)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(mintColor.opacity(0.15))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    private func foodCard(_ food: DietLog) -> some View {
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
                    Text(food.amountText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("\(Int(food.calories)) kcal")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(mintColor)
                }
                Spacer()
            }
            
            Divider()
            
            ServingSliderView(servings: $foodServings, tint: mintColor)
            
            Divider()
            
            VStack(spacing: 12) {
                NutritionBar(label: "탄수화물", value: food.carbs, ratio: food.carbRatio, color: carbColor)
                NutritionBar(label: "단백질", value: food.protein, ratio: food.proteinRatio, color: proteinColor)
                NutritionBar(label: "지방", value: food.fat, ratio: food.fatRatio, color: fatColor)
            }
            
            // 통합 액션 버튼 (클릭 시 선택 창 오픈)
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
                .background(mintColor)
                .cornerRadius(12)
                .shadow(color: mintColor.opacity(0.3), radius: 6, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
    
    // MARK: - 저장 / 통신
    enum SaveMode { case drinkOnly, foodOnly, both }
    
    private func saveLog(mode: SaveMode) {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        // 술은 "병"(하이볼은 "캔") 단위로 기록 (예: 0.5병)
        let drinkLog = DietLog(
            userId: currentUserId,
            mealType: selectedMeal,
            foodName: spec.logName,
            amount: totalBottles,
            calories: drinkCalories,
            carbs: 0.0,
            protein: 0.0,
            fat: 0.0,
            imageUrl: "",
            eatenAt: currentTimeString,
            unit: spec.containerName
        )
        
        Task {
            if mode == .drinkOnly || mode == .both {
                try? await NetworkManager.shared.saveDietLog(log: drinkLog)
            }
            
            if mode == .foodOnly || mode == .both {
                if var foodLog = scaledFood {
                    foodLog.userId = currentUserId
                    foodLog.mealType = selectedMeal
                    foodLog.eatenAt = currentTimeString
                    
                    try? await NetworkManager.shared.saveDietLog(log: foodLog)
                }
            }
        }
    }
    
    private func fetchPairing() async {
        isLoadingPairing = true
        do {
            let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
            let food = try await NetworkManager.shared.fetchDrinkPairing(drink: spec.pairingKey, userId: currentUserId)
            recommendedFood = food
            foodServings = 1.0
        } catch {
            print("안주 로딩 실패: \(error)")
        }
        isLoadingPairing = false
    }
}
