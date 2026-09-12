
import SwiftUI

// 💡 텍스트 입력 등록 시트를 위한 임시 음식 데이터 생성 함수
func getSampleData(for name: String) -> DietLog {
    return DietLog(
        diet_log_id: Int.random(in: 1000...9999),
        user_id: 1,
        meal_type: "lunch",
        food_name: name.isEmpty ? "입력한 음식" : name,
        amount: "1인분 (300g)",
        calorie: 420.0,
        protein: 24.0,
        carb: 55.0,
        fat: 12.0,
        image_url: "unnamed",
        eaten_at: "2026-05-28 12:30",
        created_at: ""
    )
}

struct FoodMainView : View {
    
    // MARK: - 색상 정의
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    let lightMint = Color.mintColor.opacity(0.15)
    
    // 탄단지 색상
    static let carbColor = Color(red: 0.98, green: 0.85, blue: 0.60)       // 탄수화물 (더 또렷하고 따뜻한 베이지)
    static let proteinColor = Color(red: 0.98, green: 0.50, blue: 0.55)   // 단백질 (밝고 선명해진 코랄 핑크)
    static let fatColor = Color(red: 1.00, green: 0.88, blue: 0.35)       // 지방
    
    let log: DietLog = DietLog(
        diet_log_id: 101,
        user_id: 1,
        meal_type: "lunch",
        food_name: "닭가슴살 샐러드",
        amount: "250g",
        calorie: 350.0,
        protein: 35.0,
        carb: 15.0,
        fat: 8.0,
        image_url: "unnamed",
        eaten_at: "2026-05-28 12:30",
        created_at: "2026-05-28 12:35"
    )
    
    @State private var selectedMeal = "아침"
    @State private var showCamera = false
    @State private var showTextEnrollSheet = false
    @State private var showHistorySheet = false
    @State private var showAddConfirmationAlert = false
    
    // 오늘 섭취 기록 데이터 배열
    @State private var todayLogs: [DietLog] = [
        DietLog(diet_log_id: 1, user_id: 1, meal_type: "아침", food_name: "사과 & 요거트", amount: "1접시", calorie: 180, protein: 4, carb: 28, fat: 3, image_url: "unnamed", eaten_at: "08:30", created_at: ""),
        DietLog(diet_log_id: 2, user_id: 1, meal_type: "점심", food_name: "현미밥 & 고등어구이", amount: "1인분", calorie: 450, protein: 32, carb: 60, fat: 11, image_url: "unnamed", eaten_at: "12:15", created_at: "")
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 타이틀 웰컴 멘트 ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘도 건강하게 먹어봐요! ")
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
                            .foregroundColor(mintColor.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("오늘 섭취한 식단 보기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("총 \(todayLogs.count)개의 기록이 있어요")
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
                
                // --- 3. 오늘 먹은 식단 추가하기 구분 영역 ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("오늘 먹은 식단 추가하기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("다양한 방법으로 오늘의 식단을 간편하게 기록해보세요.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // --- 4. 식단 추가 버튼 그룹 (텍스트 및 아이콘 민트색 변경 영역) ---
                HStack(spacing: 14) {
                    // [버튼 A] 사진으로 기록하기
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("사진으로 등록")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(mintColor) // or .black
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(selectedMint)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(mintColor, lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    
                    // [버튼 B] 텍스트 검색으로 기록하기
                    Button(action: {
                        showTextEnrollSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .bold))
                            Text("음식 검색 등록")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(mintColor) // or .black
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(selectedMint)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(mintColor, lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // --- 5. 추천 메뉴 바로 등록하기 버튼 ---
                Button(action: {
                    showAddConfirmationAlert = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("추천 메뉴를 식단으로 추가하기")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(mintColor.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(color: mintColor.opacity(0.15), radius: 5, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .alert("이 메뉴로 추가하시겠습니까?", isPresented: $showAddConfirmationAlert) {
                    Button("취소", role: .cancel) { }
                    Button("추가하기", role: .none) {
                        let newLog = DietLog(
                            diet_log_id: Int.random(in: 1...999),
                            user_id: 1,
                            meal_type: selectedMeal,
                            food_name: log.food_name,
                            amount: log.amount,
                            calorie: log.calorie,
                            protein: log.protein,
                            carb: log.carb,
                            fat: log.fat,
                            image_url: log.image_url,
                            eaten_at: "방금 전",
                            created_at: ""
                        )
                        todayLogs.append(newLog)
                    }
                } message: {
                    Text("선택된 식사: \(selectedMeal)\n메뉴: \(log.food_name) \(log.amount)\n칼로리: \(Int(log.calorie)) ")
                }
                
                Divider()
                    .padding(.horizontal, 24)
                
                // --- 6. 메뉴 추천 기능 메인 카드 영역 ---
                VStack(spacing: 0) {
                    Text("지금 드리는 추천 메뉴")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(mintColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    HStack {
                        Picker("식사 선택", selection: $selectedMeal) {
                            Text("아침").tag("아침")
                            Text("점심").tag("점심")
                            Text("저녁").tag("저녁")
                        }
                        .pickerStyle(.menu)
                        .tint(mintColor)
                        .scaleEffect(1.3)
                        .padding(.leading, 8)
                        
                        Text("에 이 메뉴 어때요?")
                            .font(.system(size: 20, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                
                Image(log.image_url ?? "unnamed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                
                // 추천 음식 세부 정보 카드
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.food_name)
                                .font(.title2.bold())
                            Text(log.amount)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(log.calorie)) kcal")
                            .font(.title3.bold())
                            .foregroundColor(mintColor)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 18) {
                        NutritionBar(label: "탄수화물", value: log.carb, ratio: log.carbRatio, color: Self.carbColor)
                        NutritionBar(label: "단백질", value: log.protein, ratio: log.proteinRatio, color: Self.proteinColor)
                        NutritionBar(label: "지방", value: log.fat, ratio: log.fatRatio, color: Self.fatColor)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 32) 
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraContainerView(showCamera: $showCamera)
        }
        .sheet(isPresented: $showTextEnrollSheet) {
            FoodTextEnrollSheet(isPresented: $showTextEnrollSheet, selectedMeal: selectedMeal, todayLogs: $todayLogs)
        }
        .sheet(isPresented: $showHistorySheet) {
            TodayHistorySheet(isPresented: $showHistorySheet, logs: $todayLogs)
        }
    }
}

// --- 보조 컴포넌트 1: 음식 이름 직접 입력 및 검색 등록 시트 뷰 ---
struct FoodTextEnrollSheet: View {
    @Binding var isPresented: Bool
    let selectedMeal: String
    @Binding var todayLogs: [DietLog]
    
    @State private var inputFoodName = ""
    
    // MARK: - 색상 정의
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("어떤 음식을 드셨나요?")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    TextField("예: 닭가슴살 볶음밥, 사과 등", text: $inputFoodName)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                .background(Color(.systemBackground))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Divider()
                
                if !inputFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let sampleFood = getSampleData(for: inputFoodName)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("📋 등록 정보 미리보기 (\(selectedMeal))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(mintColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(sampleFood.image_url ?? "unnamed")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                            
                            HStack {
                                Text(sampleFood.food_name)
                                    .font(.title3.bold())
                                Spacer()
                                Text("\(Int(sampleFood.calorie)) kcal")
                                    .font(.title3.bold())
                                    .foregroundColor(mintColor)
                            }
                            
                            VStack(spacing: 14) {
                                NutritionBar(label: "탄수화물", value: sampleFood.carb, ratio: 0.4, color: FoodMainView.carbColor)
                                NutritionBar(label: "단백질", value: sampleFood.protein, ratio: 0.6, color: FoodMainView.proteinColor)
                                NutritionBar(label: "지방", value: sampleFood.fat, ratio: 0.2, color: FoodMainView.fatColor)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(18)
                        .padding(.horizontal, 24)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("취소")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            todayLogs.append(sampleFood)
                            isPresented = false
                        }) {
                            Text("등록하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(mintColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
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
}

// --- 보조 컴포넌트 2: 오늘 섭취한 식단 확인용 리스트 시트 뷰 ---
struct TodayHistorySheet: View {
    @Binding var isPresented: Bool
    @Binding var logs: [DietLog]
    
    // MARK: - 색상 정의
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    var body: some View {
        NavigationStack {
            VStack {
                if logs.isEmpty {
                    Spacer()
                    Text("오늘 기록된 식단이 없습니다.\n상단의 추천 메뉴나 등록 기능으로 채워보세요!")
                        .font(.system(size: 15))
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
                                Text("\(Int(logs.reduce(0) { $0 + $1.calorie })) kcal")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(mintColor)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section(header: Text("기록된 타임라인")) {
                            ForEach(logs, id: \.diet_log_id) { item in
                                HStack(spacing: 16) {
                                    Text(item.meal_type)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedMint)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(mintColor, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.food_name)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(item.amount)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(item.calorie)) kcal")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteLog)
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
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }
    
    private func deleteLog(at offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
    }
}

#Preview {
    FoodMainView()
}
