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
