import Foundation
import SwiftUI


import Foundation
import SwiftUI

// MARK: - Spoonacular API 및 매니저 (기존 비즈니스 로직 유지)
struct SpoonacularWineResponse: Codable { let recommendedWines: [SpoonacularWine]? }
struct SpoonacularWine: Codable {
    let id: Int; let title: String; let description: String; let price: String?; let imageUrl: String?; let averageRating: Double?; let ratingCount: Int?; let nutrition: SpoonacularNutrition?
}
struct SpoonacularNutrition: Codable { let nutrients: [SpoonacularNutrient]? }
struct SpoonacularNutrient: Codable { let name: String; let amount: Double; let unit: String }
struct SpoonacularPairingResponse: Codable { let pairedFoods: [String]?; let pairingText: String? }

class SpoonacularManager {
    static let shared = SpoonacularManager()
    //나
    private let apiKey = "3d06b3b3cdd14e5bbd514bc5daca5f72"
    // 주영 private let apiKey = "1c5a1b3ff6ff48c5a534752c1c8fedba"
    // 민진 private let apiKey = "5defd56ce78748a5b9cc715eb05c6410"
    
    private func extractWineVariety(from wineName: String) -> String {
        let lowercasedName = wineName.lowercased()
        
        // 복합 품종(띄어쓰기 포함)을 먼저 체크해야 정확히 걸러집니다.
        // Spoonacular가 잘 인식하는 스네이크 케이스(_) 형태로 매핑합니다.
        let varieties = [
            "pinot noir": "pinot_noir",
            "sauvignon blanc": "sauvignon_blanc",
            "cabernet sauvignon": "cabernet_sauvignon",
            "chardonnay": "chardonnay",
            "merlot": "merlot",
            "cabernet": "cabernet_sauvignon",
            "shiraz": "shiraz",
            "syrah": "syrah",
            "riesling": "riesling",
            "champagne": "champagne",
            "prosecco": "prosecco",
            "zinfandel": "zinfandel",
            "rose": "rose",
            "port": "port",
            "moscato": "moscato",
            "bordeaux": "bordeaux"
        ]
        
        for (keyword, apiValue) in varieties {
            if lowercasedName.contains(keyword) {
                return apiValue
            }
        }
        
        // 카테고리 힌트 처리
        if lowercasedName.contains("white") { return "chardonnay" }
        if lowercasedName.contains("red") { return "merlot" }
        if lowercasedName.contains("sparkling") { return "champagne" }
        if lowercasedName.contains("rose") { return "rose" }
        if lowercasedName.contains("dessert") { return "port" }
        
        // 완전히 매치되는 게 없다면, API가 널리 인식하는 기본값인 'merlot'이나 'chardonnay'를 반환하는 것이 'wine'보다 안전합니다.
        return "merlot"
    }
    
    
    // 와인 정보 가져오는 함수 (WineDietLog 배열 반환)
    func fetchWines(for type: String) async -> [WineDietLog] { // 와인 정보 가져오는 함수
        let urlString = "https://api.spoonacular.com/food/wine/recommendation?wine=\(type)&number=10&includeNutrition=true&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] } //url 생성 실패시 빈배열 반환 후 종료
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(SpoonacularWineResponse.self, from: data) //data를 spoonacularWineResponse구조체로 변환(파싱)
            
            
            var mappedWines: [WineDietLog] = []
            for wine in decoded.recommendedWines ?? [] {
                let isWhite = type.contains("white")
                var calories = isWhite ? 121.0 : 125.0 //화이트와인 기본 칼로리값은 121
                
                if let nutrients = wine.nutrition?.nutrients { // 칼로리 덮어쓰기
                    if let calAmount = nutrients.first(where: { $0.name.lowercased() == "calories" })?.amount { calories = calAmount }
                }

                // 서버에서 받아온 와인 정보를 WineDietLog 객체를 생성하여 mappedWines에 추가
                mappedWines.append(WineDietLog(diet_log_id: wine.id, user_id: 1, meal_type: "snack", name: wine.title, amount: "1잔 (5oz / 148ml 기준)", calorie: calories, image_url: wine.imageUrl ?? "", eaten_at: "", created_at: "", wineDescription: wine.description))
            }
            return mappedWines
        } catch {
            print("❌ 와인 데이터 파싱 실패: \(error)")
            return []
        }
    }
    
    // 음식이름 추출한 거로 칼로리, 탄단지 , 사진 가져옴
    func fetchPairingFood(for wineName: String) async -> RecoDietLog {
        
        // 1. 입력받은 와인 이름에 맞춰 품종을 동적 추출
        let pureVariety = extractWineVariety(from: wineName)
        print("🔍 입력된 와인: \(wineName) -> 추출된 품종 키워드: \(pureVariety)")
        
        // 🌟 정제된 pureVariety를 API 쿼리에 전달
        guard let encodedName = pureVariety.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spoonacular.com/food/wine/pairing?wine=\(encodedName)&apiKey=\(apiKey)") else {
            return defaultPairing()
        }
        
        do {
            // 1. 와인 페어링 API 호출
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(SpoonacularPairingResponse.self, from: data)
            
            if decoded.pairedFoods == nil || decoded.pairedFoods?.isEmpty == true {
                print("⚠️ Spoonacular API가 이 와인 품종(\(pureVariety))에 대한 안주 추천을 제공하지 않습니다. (pairedFoods가 비어있음)")
            }

            // 페어링 음식 이름 추출 (만약 비어있다면 기본 fallback 리스트에서 랜덤 추출)
            let fallbackFoods = ["Cheese", "Crackers", "Steak", "Salmon", "Pasta"]
            var foodName = decoded.pairedFoods?.randomElement()?.capitalized ?? fallbackFoods.randomElement()!
            
            
            // 기본값 설정 (API 검색 실패나 영양소 누락 시 사용할 예비값)
            var foodImageUrl = "unnamed"
            var calorie = 250.0
            var protein = 5.0
            var carb = 20.0
            var fat = 10.0
            
            guard let encodedFoodName = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return defaultPairing()
            }
            
            
            
            // 검색 결과를 5개(number=5) 요청하여 다양성을 확보합니다.
            let searchUrlString = "https://api.spoonacular.com/recipes/complexSearch?query=\(encodedFoodName)&addRecipeNutrition=true&number=5&apiKey=\(apiKey)"
            
            if let searchUrl = URL(string: searchUrlString) {
                do {
                    let (searchData, _) = try await URLSession.shared.data(from: searchUrl)
                    let searchDecoded = try JSONDecoder().decode(SpoonacularRecipeSearchResponse.self, from: searchData)
                    
                    if let randomResult = searchDecoded.results?.randomElement() {
                                        foodImageUrl = randomResult.image
                                        foodName = randomResult.title
                        print("📸 매칭된 안주 (\(foodName)) 이미지 URL: \(foodImageUrl)")
                        // 영양소 배열에서 칼로리 및 탄단지 추출하기
                        if let nutrients = randomResult.nutrition?.nutrients {
                            if let cal = nutrients.first(where: { $0.name.lowercased() == "calories" })?.amount { calorie = cal }
                            if let pro = nutrients.first(where: { $0.name.lowercased() == "protein" })?.amount { protein = pro }
                           if let car = nutrients.first(where: { $0.name.lowercased() == "carbohydrates" })?.amount { carb = car }
                           if let f = nutrients.first(where: { $0.name.lowercased() == "fat" })?.amount { fat = f }}
                    } else {
                        print("⚠️ 레시피 검색 결과가 비어있습니다. 기본 안주명으로 매핑합니다.")
                    }
                } catch {
                    print("❌ 레시피 복합 검색 및 영양소 파싱 에러: \(error)")
                }
            }
            
            // 3. 최종 데이터 매핑 후 반환
            let log = RecoDietLog(
                diet_log_id: Int.random(in: 1000...9999),
                user_id: 1,
                meal_type: "snack",
                food_name: foodName,
                amount: "1인분 기준",
                calorie: calorie,
                protein: protein,
                carb: carb,
                fat: fat,
                image_url: foodImageUrl,
                eaten_at: "",
                created_at: "",
                pairingDescription: decoded.pairingText ?? "음식에 대한 설명이 없습니다."
            )
            
            return log
            
        } catch {
            print("❌ 외부 페어링 API 호출 또는 디코딩 실패: \(error)")
            return defaultPairing()
        }
    }
    
    // 에러 발생 시 사용할 기본 페어링 데이터 함수 (RecoDietLog 반환하도록 수정)
    private func defaultPairing() -> RecoDietLog {
        let log = RecoDietLog(
            diet_log_id: 101,
            user_id: 1,
            meal_type: "snack",
            food_name: "치즈 & 크래커 플래터",
            amount: "1접시 기준",
            calorie: 320,
            protein: 10.0,
            carb: 20.0,
            fat: 30.0,
            image_url: "unnamed",
            eaten_at: "",
            created_at: "",
            pairingDescription: "모둠 치즈와 크래커 구성입니다."
        )
        return log
    }
}

// MARK: - 이미지 기반 깔끔한 라이트 테마 컬러셋
extension Color {
    static let uiBackground = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let uiCardBg = Color.white
}

// MARK: - 메인 뷰 (DrinkWineView)
struct DrinkWineView: View {
    @State private var whiteWines: [WineDietLog] = []
    @State private var redWines: [WineDietLog] = []
    @State private var sparklingWines: [WineDietLog] = []
    @State private var roseWines: [WineDietLog] = []
    @State private var dessertWines: [WineDietLog] = []
    @State private var selectedWineLog: WineDietLog? = nil
    
    @State private var selectedCategory: String = "화이트"
    let categories = ["🥂화이트", "🍷레드", "🍾스파클링", "🌸로제", "🍰디저트와인"]
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 3)
    
    private var currentWines: [WineDietLog] {
        if selectedCategory.contains("화이트") { return whiteWines }
        if selectedCategory.contains("레드") { return redWines }
        if selectedCategory.contains("스파클링") { return sparklingWines }
        if selectedCategory.contains("로제") { return roseWines }
        if selectedCategory.contains("디저트와인") { return dessertWines }
        return []
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 헤더 영역
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text("오늘의 와인")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                        Text("🍷")
                            .font(.system(size: 24))
                    }
                    //.padding(.top, 8 )
                    
                    Text("어울리는 안주까지 한 번에")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                    
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        Text("어떤 와인을 찾으시나요?")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.placeholderText))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.top, 20)
                    .padding(.bottom , 20)
                    
                    // 카테고리 탭 바
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    if cat.contains("화이트") { selectedCategory = "화이트" }
                                    else if cat.contains("레드") { selectedCategory = "레드" }
                                    else if cat.contains("스파클링") { selectedCategory = "스파클링" }
                                    else if cat.contains("로제") { selectedCategory = "로제" }
                                    else if cat.contains("디저트와인") { selectedCategory = "디저트와인" }
                                }) {
                                    
                                    let currentKey = cat.contains("화이트") ? "화이트" :
                                    cat.contains("레드") ? "레드" :
                                    cat.contains("스파클링") ? "스파클링" :
                                    cat.contains("로제") ? "로제" :
                                    cat.contains("디저트와인") ? "디저트와인" : cat
                                    
                                    Text(cat)
                                        .font(.system(size: 14, weight: selectedCategory == currentKey ? .bold : .regular))
                                        .foregroundColor(selectedCategory == currentKey ? .white : .gray)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 22)
                                    
                                        .background(selectedCategory == currentKey ? Color.black : Color.white)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedCategory == currentKey ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                    }
                }
                    .padding(.horizontal, 10)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                }
                   .padding(.horizontal, 5)
                   .background(Color.white)
                            
                // 4. 하단 콘텐츠 영역
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("BEST 10 추천")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 12)
                        
                        if currentWines.isEmpty {
                            VStack {
                                ProgressView("와인 리스트를 불러오는 중...")
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(currentWines) { wineData in
                                    WineGridItem(wineData: wineData)
                                        .onTapGesture {
                                            selectedWineLog = wineData
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                }
            }
            .task {
                let white = await SpoonacularManager.shared.fetchWines(for: "white_wine")
                let red = await SpoonacularManager.shared.fetchWines(for: "red_wine")
                let sparkling = await SpoonacularManager.shared.fetchWines(for: "sparkling_wine")
                let rose = await SpoonacularManager.shared.fetchWines(for: "rose_wine")
                let dessert = await SpoonacularManager.shared.fetchWines(for: "dessert_wine")
                
                
        
                self.whiteWines = white.isEmpty ? createDummyWines(type: "Chardonnay") : white
                self.redWines = red.isEmpty ? createDummyWines(type: "Cabernet") : red
                self.sparklingWines = sparkling.isEmpty ? createDummyWines(type: "Champagne") : sparkling
                self.roseWines = rose.isEmpty ? createDummyWines(type: "Zinfandel") : rose
                self.dessertWines = dessert.isEmpty ? createDummyWines(type: "Port") : dessert
            }
            .sheet(item: $selectedWineLog) { wine in
                WineDetailSheet(wine: wine)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func createDummyWines(type: String) -> [WineDietLog] {
        (1...10).map { index in
            WineDietLog(
                diet_log_id: index,
                user_id: 1,
                meal_type: "snack",
                name: "\(type) Premium No.\(index)",
                amount: "700ml",
                calorie: Double.random(in: 120...130),
                image_url: nil,
                eaten_at: "",
                created_at: ""
            )
        }
    }


// MARK: - 3열 격자 뷰 컴포넌트
struct WineGridItem: View {
    let wineData: WineDietLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.white
                AsyncImage(url: URL(string: wineData.image_url ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Image(systemName: "wineglass")
                            .font(.system(size: 24))
                            .foregroundColor(Color(.gray))
                    }
                }
                .padding(10)
            }
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(wineData.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 32, alignment: .topLeading)
                
                Text("\(Int(wineData.calorie)) kcal")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
                
            }
            .padding(.top, 6)
            .padding(.horizontal, 2)
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 165)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 와인 상세 정보 시트
struct WineDetailSheet: View {
    let wine: WineDietLog
    @Environment(\.dismiss) private var dismiss
    @State private var showWineAlert = false       // 와인 등록용 알럿 상태
    @State private var showFoodAlert = false       // 안주 등록용 알럿 상태
    @State private var recommendedFood: RecoDietLog? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. 와인 이미지 영역
                HStack {
                    Spacer()
                    AsyncImage(url: URL(string: wine.image_url ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                        } else {
                            Image(systemName: "wineglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .frame(width: 180, height: 180)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // 2. 와인 텍스트 정보 영역
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(wine.name)
                            .font(.system(size: 24, weight: .bold))
                        Spacer()
                        Text("\(Int(wine.calorie)) kcal")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    Text(wine.amount)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    let description = wine.wineDescription ?? ""
                        Text(description.isEmpty ? "풍부한 향과 깔끔한 목 넘김으로 누구나 부담 없이 즐기기 좋은 와인입니다." : description)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                }
                
                Divider()
                
                // 3. 추천 페어링 안주 및 버튼 영역
                if let food = recommendedFood {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("✨ 소믈리에 추천 페어링")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(food.food_name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.vertical , 10)
                                Spacer()
                                Text("\(Int(food.calorie)) kcal")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            if let descriptionText = food.pairingDescription {
                                Text(descriptionText)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .lineSpacing(6)
                            }
                            
                            VStack(spacing: 16) {
                                // 안주 이미지 로드
                                AsyncImage(url: URL(string: food.image_url ?? "")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 180)
                                            .cornerRadius(12)
                                            .clipped()
                                    } else if food.image_url == "unnamed" {
                                        // 이미지가 없거나 플레이스홀더 상태일 때
                                        VStack {
                                            Image(systemName: "fork.knife")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray)
                                            Text("이미지를 찾을 수 없습니다")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    } else {
                                        // 로딩 중 인디케이터
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 180)
                                            .background(Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                // 탄단지 NutritionBar 리스트
                                VStack(spacing: 12) {
                                    NutritionBar(
                                        label: "탄수화물",
                                        value: food.carb,
                                        ratio: food.carbRatio,
                                        color: .blue
                                    )
                                    
                                    NutritionBar(
                                        label: "단백질",
                                        value: food.protein,
                                        ratio: food.proteinRatio,
                                        color: .orange
                                    )
                                    
                                    NutritionBar(
                                        label: "지방",
                                        value: food.fat,
                                        ratio: food.fatRatio,
                                        color: .green
                                    )
                                }
                                .padding(.top, 4)
                            }
                            .padding(.bottom, 15)
                            
                        
                            
                            
                            // 하단 버튼 두 개 (가로 배열)
                            HStack(spacing: 12) {
                                // 와인 추가 버튼
                                Button(action: { showWineAlert = true }) {
                                    Text("와인을\n 식단에 추가하기")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(Color.black)
                                        .cornerRadius(14)
                                }
                                .alert("식단 등록", isPresented: $showWineAlert) {
                                    Button("취소", role: .cancel) {}
                                    Button("추가", role: .none) { dismiss() }
                                } message: {
                                    Text("\(wine.name)을 추가하시겠습니까?")
                                }
                                
                                // 추천 안주 추가 버튼
                                Button(action: { showFoodAlert = true }) {
                                    Text("추천 메뉴를\n 식단에 추가하기")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(Color.black)
                                        .cornerRadius(14)
                                }
                                .alert("식단 등록", isPresented: $showFoodAlert) {
                                    Button("취소", role: .cancel) {}
                                    Button("추가", role: .none) { dismiss() }
                                } message: {
                                    Text("\(food.food_name)을 추가하시겠습니까?")
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                } else {
                    // 데이터를 로딩 중일 때 보여주는 인디케이터
                    HStack {
                        Spacer()
                        ProgressView("추천 안주를 불러오는 중...")
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(20)
        }
        .task {
            // 시트가 열릴 때 API 호출
            self.recommendedFood = await SpoonacularManager.shared.fetchPairingFood(for: wine.name)
        }
    }
}
