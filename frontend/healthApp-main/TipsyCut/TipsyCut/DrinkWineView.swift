import SwiftUI

struct DrinkWineView: View {
    
    // 개별 와인 이름 정의
    let whiteWines = ["wine1", "wine2", "wine3"]
    let redWines = ["wine4", "wine5", "wine6"]
    let sparklingWines = ["wine7", "wine8", "wine9"]
    
    @State private var selectedWineLog: DietLog? = nil
    @State private var searchwine = false
    @State private var isShowingSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- 상단 헤더 영역 ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("와인")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.init(white: 0.2))
                        
                        Text("에 맞는 음식을 추천해드려요")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    HStack {
                        Text("와인 이름을 검색해 보세요!")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        NavigationLink(destination: DrinkWineSearchView()) {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.brown)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
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
                        wineSection(title: "화이트 와인", images: whiteWines)
                        wineSection(title: "레드 와인", images: redWines)
                        wineSection(title: "스파클링 와인", images: sparklingWines)
                    }
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .sheet(item: $selectedWineLog) { wine in
            WineDetailSheet(wine: wine)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // --- 가로 캐러셀 뷰 빌더 함수 ---
    @ViewBuilder
    private func wineSection(title: String, images: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(images, id: \.self) { imageName in
                        let wineData = getWineData(for: imageName)
                        let isSelected = selectedWineLog?.foodName == wineData.foodName
                        
                        VStack(spacing: 12) {
                            Image(wineData.imageUrl ?? imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 150)
                                .cornerRadius(8)
                            
                            Text(wineData.foodName)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .frame(width: 140)
                        .background(isSelected ? Color.brown.opacity(0.1) : Color(.systemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.brown : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWineLog = wineData
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
    }
    
    func getWineData(for wineName: String) -> DietLog {
        // 💡 실제 로그인 유저 ID와 현재 시간 동적 할당
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        switch wineName {
        case "wine1": return DietLog(userId: currentUserId, mealType: "간식", foodName: "샤르도네", amount: 1.0, calories: 120, carbs: 3.2, protein: 0.1, fat: 0.0, imageUrl: "wine1", eatenAt: currentTimeString)
        case "wine2": return DietLog(userId: currentUserId, mealType: "간식", foodName: "소비뇽 블랑", amount: 1.0, calories: 115, carbs: 3.0, protein: 0.1, fat: 0.0, imageUrl: "wine2", eatenAt: currentTimeString)
        case "wine3": return DietLog(userId: currentUserId, mealType: "간식", foodName: "리슬링", amount: 1.0, calories: 125, carbs: 4.5, protein: 0.1, fat: 0.0, imageUrl: "wine3", eatenAt: currentTimeString)
        case "wine4": return DietLog(userId: currentUserId, mealType: "간식", foodName: "카베르네 소비뇽", amount: 1.0, calories: 125, carbs: 3.8, protein: 0.1, fat: 0.0, imageUrl: "wine4", eatenAt: currentTimeString)
        case "wine5": return DietLog(userId: currentUserId, mealType: "간식", foodName: "피노 누아", amount: 1.0, calories: 121, carbs: 3.4, protein: 0.1, fat: 0.0, imageUrl: "wine5", eatenAt: currentTimeString)
        case "wine6": return DietLog(userId: currentUserId, mealType: "간식", foodName: "말벡", amount: 1.0, calories: 130, carbs: 3.9, protein: 0.1, fat: 0.0, imageUrl: "wine6", eatenAt: currentTimeString)
        case "wine7": return DietLog(userId: currentUserId, mealType: "간식", foodName: "샴페인", amount: 1.0, calories: 95, carbs: 1.5, protein: 0.1, fat: 0.0, imageUrl: "wine7", eatenAt: currentTimeString)
        case "wine8": return DietLog(userId: currentUserId, mealType: "간식", foodName: "프로세코", amount: 1.0, calories: 90, carbs: 2.0, protein: 0.1, fat: 0.0, imageUrl: "wine8", eatenAt: currentTimeString)
        default: return DietLog(userId: currentUserId, mealType: "간식", foodName: "모스카토 다스티", amount: 1.0, calories: 130, carbs: 7.5, protein: 0.2, fat: 0.0, imageUrl: "wine9", eatenAt: currentTimeString)
        }
    }
}

// --- 하단 시트 뷰 상세 구성 ---
struct WineDetailSheet: View {
    let wine: DietLog
    
    @Environment(\.dismiss) private var dismiss
    
    // 💡 식사 분류 기본값 설정 및 Picker 연동
    @State private var selectedMeal = "저녁"
    
    // 💡 분리 기록을 위한 Action Sheet 상태 변수
    @State private var showSaveOptions = false
    
    @State private var recommendedFood: DietLog? = nil
    @State private var isLoadingPairing = true
    
    // 💡 잔 단위 주량 기록 및 칼로리 계산 (와인 1잔 = 약 150ml)
    @State private var drinkAmount: Double = 1.0
    var calculatedDrinkCalories: Double {
        // 선택한 와인의 고유 칼로리에 잔 수를 곱합니다.
        return drinkAmount * wine.calories
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 와인 이미지 및 기본 정보
                HStack {
                    Spacer()
                    Image(wine.imageUrl ?? "wine1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 220)
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // --- 🌟 주량 입력 슬라이더 및 식사 분류 Picker ---
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wine.foodName)
                                    .font(.title2).bold()
                                Text("오늘 마신 양")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(drinkAmount)) 잔 (150ml)")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.brown)
                                Text("+\(Int(calculatedDrinkCalories)) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Slider(value: $drinkAmount, in: 0...10, step: 1.0)
                            .tint(.brown)
                    }
                    
                    Divider()
                    
                    // 💡 식사 시간 분류 Picker
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
                        .foregroundColor(.brown)
                    
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
                                    .foregroundColor(.brown)
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
                        
                        // 🌟 통합 액션 버튼 (클릭 시 선택 창 오픈)
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
                            .background(Color.brown)
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
                    self.recommendedFood = try await NetworkManager.shared.fetchDrinkPairing(drink: wine.foodName, userId: currentUserId)
                } catch {
                    print("안주 로딩 실패: \(error)")
                }
                isLoadingPairing = false
            }
        }
        // 🌟 분리 저장을 위한 Action Sheet (Confirmation Dialog)
        .confirmationDialog("무엇을 식단에 기록할까요?", isPresented: $showSaveOptions, titleVisibility: .visible) {
            
            Button("와인만 기록하기") {
                saveLog(mode: .drinkOnly)
            }
            
            if recommendedFood != nil {
                Button("추천 안주만 기록하기") {
                    saveLog(mode: .foodOnly)
                }
                
                Button("와인 + 안주 둘 다 기록하기") {
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
        // 💡 1. 기기에서 로그인된 유저 ID 가져오기
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        
        // 💡 2. 저장하는 버튼을 누른 '현재 시간' 실시간 연동
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        let drinkLog = DietLog(
            userId: currentUserId,
            mealType: selectedMeal, // 💡 Picker에서 선택한 값 적용
            foodName: wine.foodName,
            amount: drinkAmount,
            calories: calculatedDrinkCalories,
            carbs: wine.carbs,
            protein: wine.protein,
            fat: wine.fat,
            imageUrl: wine.imageUrl,
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
    DrinkWineView()
}
