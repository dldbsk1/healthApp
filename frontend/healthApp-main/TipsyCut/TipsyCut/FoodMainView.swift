import SwiftUI

struct FoodMainView : View {
    
    // 백엔드에서 받아올 실제 데이터들을 담을 변수
    @State private var dailyLogs: [DietLog] = []
    @State private var totalCalories: Double = 0.0
    
    @State private var selectedMeal = "아침"
    @State private var showCamera = false
    @State private var showTextEnrollSheet = false
    @State private var showHistorySheet = false
    @State private var showAddConfirmationAlert = false
    
    let dietTypes = ["일반 균형식", "고단백", "키토제닉", "지중해식", "비건채식"]
    @State private var selectedDietType = "일반 균형식"
    
    @State private var recommendedLog: DietLog?
    @State private var isRecommendationLoading = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 타이틀 웰컴 멘트 ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘도 건강하게 먹어봐요! 🌱")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("규칙적인 식습관이 건강한 하루를 만듭니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // --- 2. 오늘 섭취한 식단 보기 대시보드 바 ---
                Button(action: {
                    showHistorySheet = true
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("오늘 섭취한 식단 보기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("총 \(dailyLogs.count)개의 기록이 있어요")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // --- 3. 식단 추가 버튼 그룹 ---
                HStack(spacing: 14) {
                    Button(action: { showCamera = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("사진으로 등록")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                        .shadow(color: Color.purple.opacity(0.15), radius: 4, x: 0, y: 3)
                    }
                    
                    Button(action: { showTextEnrollSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .bold))
                            Text("음식 검색 등록")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(color: Color.orange.opacity(0.15), radius: 4, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // --- 4. 맞춤형 식단 추천 영역 ---
                VStack(spacing: 0) {
                    Text("✨ 나의 목표에 맞는 메뉴 추천")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(dietTypes, id: \.self) { diet in
                                Button(action: {
                                    selectedDietType = diet
                                    Task { await fetchRecommendation(targetDiet: diet) }
                                }) {
                                    Text(diet)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedDietType == diet ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(selectedDietType == diet ? .white : .primary)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedDietType == diet ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                    }
                    
                    HStack {
                        Picker("식사 선택", selection: $selectedMeal) {
                            Text("아침").tag("아침")
                            Text("점심").tag("점심")
                            Text("저녁").tag("저녁")
                            Text("간식").tag("간식")
                            Text("야식").tag("야식")
                        }
                        .pickerStyle(.menu)
                        .scaleEffect(1.3)
                        .padding(.leading, 8)
                        
                        Text("에 이 메뉴 어때요?")
                            .font(.system(size: 20, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                
                if isRecommendationLoading {
                    ProgressView("맛있는 메뉴를 고르는 중...")
                        .frame(height: 150)
                } else if let recLog = recommendedLog {
                    VStack(spacing: 20) {
                        AsyncImage(url: URL(string: recLog.imageUrl ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recLog.foodName)
                                    .font(.title2.bold())
                                Text("\(Int(recLog.amount))g")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(recLog.calories)) kcal")
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        }
                        Divider()
                        VStack(spacing: 18) {
                            NutritionBar(label: "탄수화물", value: recLog.carbs, ratio: recLog.carbRatio, color: .blue)
                            NutritionBar(label: "단백질", value: recLog.protein, ratio: recLog.proteinRatio, color: .orange)
                            NutritionBar(label: "지방", value: recLog.fat, ratio: recLog.fatRatio, color: .green)
                        }
                        
                        Button(action: {
                            showAddConfirmationAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("이 메뉴 식단으로 추가하기")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .alert("이 메뉴로 추가하시겠습니까?", isPresented: $showAddConfirmationAlert) {
                        Button("취소", role: .cancel) { }
                        Button("추가하기", role: .none) {
                            var logToSave = recLog
                            logToSave.mealType = selectedMeal
                            
                            // 💡 추천 식단을 저장할 때도 현재 기기의 유저 아이디와 시간을 덮어씌웁니다.
                            let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                            
                            logToSave.userId = currentUserId
                            logToSave.eatenAt = formatter.string(from: Date())
                            
                            Task {
                                try? await NetworkManager.shared.saveDietLog(log: logToSave)
                                await fetchLogs()
                            }
                        }
                    } message: {
                        Text("선택된 식사: \(selectedMeal)\n메뉴: \(recLog.foodName) \(Int(recLog.amount))g\n칼로리: \(Int(recLog.calories)) kcal")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchLogs()
                await fetchRecommendation(targetDiet: selectedDietType)
            }
        }
        .sheet(isPresented: $showCamera) {
            // 💡 [수정] 다른 등록 경로와 동일하게, 저장 완료 시 목록을 다시 불러오도록 콜백 전달
            FoodCameraView(showCamera: $showCamera) {
                Task { await fetchLogs() }
            }
        }
        .sheet(isPresented: $showTextEnrollSheet) {
            FoodTextEnrollSheet(isPresented: $showTextEnrollSheet, selectedMeal: selectedMeal) {
                Task { await fetchLogs() }
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            TodayHistorySheet(isPresented: $showHistorySheet, logs: $dailyLogs, totalCalories: totalCalories)
        }
    }
    
    // 🌟 [핵심 수정] 하드코딩된 날짜를 지우고 오늘 날짜를 실시간으로 가져옵니다!
    private func fetchLogs() async {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        do {
            let response = try await NetworkManager.shared.fetchDailyDiet(userId: currentUserId, date: todayString)
            await MainActor.run {
                self.dailyLogs = response.logs
                self.totalCalories = response.totalCalories
            }
        } catch {
            print("❌ 식단 기록을 불러오지 못했습니다: \(error)")
        }
    }
    
    private func fetchRecommendation(targetDiet: String) async {
        isRecommendationLoading = true
        
        var dietKeyword = "BALANCED"
        switch targetDiet {
        case "일반 균형식": dietKeyword = "BALANCED"
        case "고단백": dietKeyword = "HIGH_PROTEIN"
        case "키토제닉": dietKeyword = "KETO"
        case "지중해식": dietKeyword = "MEDITERRANEAN"
        case "비건채식": dietKeyword = "VEGAN"
        default: dietKeyword = "BALANCED"
        }
        
        do {
            let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
            let newRecommendation = try await NetworkManager.shared.fetchRandomDietMenu(type: dietKeyword, userId: currentUserId)
            await MainActor.run {
                self.recommendedLog = newRecommendation
            }
        } catch {
            print("❌ 추천 메뉴 API 호출 실패: \(error.localizedDescription)")
            
            let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let currentTimeString = formatter.string(from: Date())
            
            await MainActor.run {
                self.recommendedLog = DietLog(
                    userId: currentUserId,
                    mealType: selectedMeal,
                    foodName: "[\(targetDiet)] 닭가슴살 샐러드",
                    amount: 250.0,
                    calories: 350.0,
                    carbs: 20.0,
                    protein: 40.0,
                    fat: 10.0,
                    imageUrl: "https://spoonacular.com/recipeImages/592479-312x231.jpg",
                    eatenAt: currentTimeString
                )
            }
        }
        
        await MainActor.run {
            isRecommendationLoading = false
        }
    }
}

// --- 보조 컴포넌트 1: 음식 검색 및 등록 시트 뷰 ---
struct FoodTextEnrollSheet: View {
    @Binding var isPresented: Bool
    let selectedMeal: String
    var onSaveComplete: () -> Void
    
    @State private var inputQuery = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isLoading = false
    @State private var selectedFood: FoodSearchResult?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    TextField("영어로 음식을 검색해보세요 (예: chicken)", text: $inputQuery)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                        )
                    
                    Button(action: {
                        Task { await performSearch() }
                    }) {
                        Text("검색")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Divider()
                
                if isLoading {
                    ProgressView("Spoonacular에서 검색 중...")
                        .frame(maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: {
                            selectedFood = result
                        }) {
                            HStack {
                                AsyncImage(url: URL(string: result.imageUrl ?? "")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading) {
                                    Text(result.foodName).font(.headline)
                                    Text("\(Int(result.calories)) kcal").font(.subheadline).foregroundColor(.blue)
                                }
                                Spacer()
                                if selectedFood?.id == result.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    
                    if let selected = selectedFood {
                        Button(action: {
                            Task { await saveToServer(food: selected) }
                        }) {
                            Text("\(selected.foodName) 등록하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("음식을 검색하시면 영양성분 정보 미리보기와\n함께 식단을 등록할 수 있습니다.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
            }
            .navigationTitle("텍스트로 음식 검색 및 등록")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func performSearch() async {
        guard !inputQuery.isEmpty else { return }
        isLoading = true
        do {
            searchResults = try await NetworkManager.shared.searchFood(query: inputQuery)
        } catch {
            print("검색 에러: \(error)")
        }
        isLoading = false
    }
    
    // 🌟 [핵심 수정] 검색한 음식을 저장할 때도 오늘 날짜와 실시간 아이디가 들어가도록 변경
    private func saveToServer(food: FoodSearchResult) async {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        let newLog = DietLog(
            userId: currentUserId,
            mealType: selectedMeal,
            foodName: food.foodName,
            amount: 1.0,
            calories: food.calories,
            carbs: food.carbs,
            protein: food.protein,
            fat: food.fat,
            imageUrl: food.imageUrl,
            eatenAt: currentTimeString
        )
        
        do {
            try await NetworkManager.shared.saveDietLog(log: newLog)
            await MainActor.run {
                onSaveComplete()
                isPresented = false
            }
        } catch {
            print("저장 에러: \(error)")
        }
    }
}

// --- 보조 컴포넌트 2: 오늘 섭취한 식단 확인용 리스트 시트 뷰 ---
struct TodayHistorySheet: View {
    @Binding var isPresented: Bool
    @Binding var logs: [DietLog]
    var totalCalories: Double
    
    var body: some View {
        NavigationStack {
            VStack {
                if logs.isEmpty {
                    Spacer()
                    Text("오늘 기록된 식단이 없습니다.\n상단의 추천 메뉴나 등록 기능으로 채워보세요!")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    List {
                        Section {
                            HStack {
                                Text("오늘 섭취한 총 칼로리")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Text("\(Int(totalCalories)) kcal")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section(header: Text("기록된 타임라인")) {
                            ForEach(logs, id: \.id) { item in
                                HStack(spacing: 16) {
                                    Text(item.mealType)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(item.mealType == "아침" ? Color.blue : (item.mealType == "점심" ? Color.orange : Color.purple))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.foodName)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("\(Int(item.amount))g")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(item.calories)) kcal")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("오늘 섭취한 식단 목록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { isPresented = false }
                }
            }
        }
    }
}
