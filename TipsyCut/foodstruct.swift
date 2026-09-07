import Foundation


struct DietLog: Identifiable, Codable {
    var id: Int { diet_log_id }
    
    let diet_log_id: Int
    let user_id: Int
    let meal_type: String     // breakfast, lunch, dinner, snack
    let food_name: String
    let amount: String        // 예: "200g"
    let calorie: Double
    let protein: Double
    let carb: Double
    let fat: Double
    let image_url: String?    // 사진이 없을 수도 있으니 옵셔널(?)
    let eaten_at: String      // 날짜 형식에 따라 String 또는 Date
    let created_at: String
    

    var carbRatio: Double { min(carb / 150.0, 1.0) }
    var proteinRatio: Double { min(protein / 75.0, 1.0) }
    var fatRatio: Double { min(fat / 50.0, 1.0) }
}

struct WineDietLog: Identifiable, Codable {
    var id: Int { diet_log_id }
    
    let diet_log_id: Int
    let user_id: Int
    let meal_type: String
    let name: String
    let amount: String
    let calorie: Double
    let image_url: String?
    let eaten_at: String
    let created_at: String
    
    var wineDescription: String? = nil
}


struct RecoDietLog: Identifiable, Codable {
    var id: Int { diet_log_id }
    
    let diet_log_id: Int
    let user_id: Int
    let meal_type: String     // breakfast, lunch, dinner, snack
    let food_name: String
    let amount: String        // 예: "200g"
    let calorie: Double
    let protein: Double
    let carb: Double
    let fat: Double
    let image_url: String?    // 사진이 없을 수도 있으니 옵셔널(?)
    let eaten_at: String      // 날짜 형식에 따라 String 또는 Date
    let created_at: String
    let pairingDescription: String?
    

    var carbRatio: Double { min(carb / 150.0, 1.0) }
    var proteinRatio: Double { min(protein / 75.0, 1.0) }
    var fatRatio: Double { min(fat / 50.0, 1.0) }
}

// Spoonacular 레시피 검색 + 영양성분 통합 응답 구조체
struct SpoonacularRecipeSearchResponse: Codable {
    let results: [SpoonacularFoodResult]?
}

struct SpoonacularFoodResult: Codable {
    let id: Int
    let title: String
    let image: String // 음식 이미지 URL
    let nutrition: SpoonacularFoodNutrition?
}

struct SpoonacularFoodNutrition: Codable {
    let nutrients: [SpoonacularFoodNutrient]?
}

struct SpoonacularFoodNutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}
