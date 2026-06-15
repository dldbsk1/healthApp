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
                        
                        NavigationLink(destination: Text("검색 화면")) {
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
                        let isSelected = selectedWineLog?.diet_log_id == wineData.diet_log_id
                        
                        VStack(spacing: 12) {
                            Image(wineData.image_url ?? imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 150)
                                .cornerRadius(8)
                            
                            Text(wineData.food_name)
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
        switch wineName {
        case "wine1":
            return DietLog(diet_log_id: 1, user_id: 1, meal_type: "snack", food_name: "샤르도네", amount: "1잔", calorie: 120, protein: 0.1, carb: 3.2, fat: 0.0, image_url: "wine1", eaten_at: "", created_at: "")
        case "wine2":
            return DietLog(diet_log_id: 2, user_id: 1, meal_type: "snack", food_name: "소비뇽 블랑", amount: "1잔", calorie: 115, protein: 0.1, carb: 3.0, fat: 0.0, image_url: "wine2", eaten_at: "", created_at: "")
        case "wine3":
            return DietLog(diet_log_id: 3, user_id: 1, meal_type: "snack", food_name: "리슬링", amount: "1잔", calorie: 125, protein: 0.1, carb: 4.5, fat: 0.0, image_url: "wine3", eaten_at: "", created_at: "")
        case "wine4":
            return DietLog(diet_log_id: 4, user_id: 1, meal_type: "snack", food_name: "카베르네 소비뇽", amount: "1잔", calorie: 125, protein: 0.1, carb: 3.8, fat: 0.0, image_url: "wine4", eaten_at: "", created_at: "")
        case "wine5":
            return DietLog(diet_log_id: 5, user_id: 1, meal_type: "snack", food_name: "피노 누아", amount: "1잔", calorie: 121, protein: 0.1, carb: 3.4, fat: 0.0, image_url: "wine5", eaten_at: "", created_at: "")
        case "wine6":
            return DietLog(diet_log_id: 6, user_id: 1, meal_type: "snack", food_name: "말벡", amount: "1잔", calorie: 130, protein: 0.1, carb: 3.9, fat: 0.0, image_url: "wine6", eaten_at: "", created_at: "")
        case "wine7":
            return DietLog(diet_log_id: 7, user_id: 1, meal_type: "snack", food_name: "샴페인", amount: "1잔", calorie: 95, protein: 0.1, carb: 1.5, fat: 0.0, image_url: "wine7", eaten_at: "", created_at: "")
        case "wine8":
            return DietLog(diet_log_id: 8, user_id: 1, meal_type: "snack", food_name: "프로세코", amount: "1잔", calorie: 90, protein: 0.1, carb: 2.0, fat: 0.0, image_url: "wine8", eaten_at: "", created_at: "")
        default:
            return DietLog(diet_log_id: 99, user_id: 1, meal_type: "snack", food_name: "모스카토 다스티", amount: "1잔", calorie: 130, protein: 0.2, carb: 7.5, fat: 0.0, image_url: "wine9", eaten_at: "", created_at: "")
        }
    }
}

// --- 하단 시트 뷰 상세 구성 ---
struct WineDetailSheet: View {
    let wine: DietLog
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal = "저녁"
    @State private var showAddConfirmationAlert = false
    
    // 🌟 가상의 'unnamed' 추천 페어링 음식 데이터 세팅
    let recommendedFood = DietLog(
        diet_log_id: 101,
        user_id: 1,
        meal_type: "snack",
        food_name: "치즈 & 크래커 플래터",
        amount: "1접시 (150g)",
        calorie: 345,
        protein: 14.5,
        carb: 22.0,
        fat: 18.5,
        image_url: "unnamed", // 👈 에셋의 음식 사진 이름
        eaten_at: "",
        created_at: ""
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Image(wine.image_url ?? "wine1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 220)
                    Spacer()
                }
                .padding(.vertical, 10)
                
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(wine.food_name)
                            .font(.title2)
                            .bold()
                        Text(wine.amount)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(Int(wine.calorie)) kcal")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.brown)
                }
                
                Divider()
                
                VStack(spacing: 16) {
                    NutritionBar(label: "탄수화물", value: wine.carb, ratio: wine.carbRatio, color: .orange)
                    NutritionBar(label: "단백질", value: wine.protein, ratio: wine.proteinRatio, color: .red)
                    NutritionBar(label: "지방", value: wine.fat, ratio: wine.fatRatio, color: .purple)
                }
                
                // ------------------------------------------------------
                // 🌟 수정된 [추천 푸드 가이드 영역] (사진 + 영양성분 + 버튼 순서)
                // ------------------------------------------------------
                Divider()
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("✨ 페어링 추천 메뉴")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.brown)
                    
                    // 1. 추천 음식 카드 (사진 및 이름/칼로리)
                    HStack(spacing: 16) {
                        Image(recommendedFood.image_url ?? "unnamed")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .clipped()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(recommendedFood.food_name)
                                .font(.system(size: 16, weight: .bold))
                            Text(recommendedFood.amount)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("\(Int(recommendedFood.calorie)) kcal")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.brown)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // 2. 추천 음식 영양성분 미니 바 (간결하게 표현)
                    VStack(spacing: 10) {
                        NutritionBar(label: "탄수화물", value: recommendedFood.carb, ratio: recommendedFood.carbRatio, color: .orange)
                        NutritionBar(label: "단백질", value: recommendedFood.protein, ratio: recommendedFood.proteinRatio, color: .red)
                        NutritionBar(label: "지방", value: recommendedFood.fat, ratio: recommendedFood.fatRatio, color: .purple)
                    }
                    .padding(.horizontal, 4)
                    
                    // 3. 식단 추가 버튼
                    Button(action: {
                        showAddConfirmationAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("추천 메뉴를 식단으로 추가하기")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brown)
                        .cornerRadius(12)
                        .shadow(color: Color.brown.opacity(0.2), radius: 4, x: 0, y: 3)
                    }
                    .alert("이 메뉴로 추가하시겠습니까?", isPresented: $showAddConfirmationAlert) {
                        Button("취소", role: .cancel) { }
                        Button("추가하기", role: .none) {
                            dismiss() // 확인 클릭 시 창 닫기
                        }
                    } message: {
                        Text("추천 메뉴: \(recommendedFood.food_name)\n\n오늘의 식단에 해당 정보가 등록됩니다.")
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                // ------------------------------------------------------
                
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    DrinkWineView()
}
