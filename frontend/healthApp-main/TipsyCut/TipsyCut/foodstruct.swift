import Foundation

// 🌟 백엔드 JSON 형식과 완벽하게 일치하도록 수정된 데이터 모델
struct DietLog: Identifiable, Codable {
    // Identifiable 프로토콜을 위한 id (MongoDB의 _id를 매핑하거나, 없다면 UUID 생성)
    var id: String { _id ?? UUID().uuidString }
    
    // 백엔드에서 내려주는 실제 데이터 필드들 (카멜 케이스 & 타입 일치)
    var _id: String?          // MongoDB가 만들어주는 고유 ID
    var userId: String        // String 타입으로 변경 (예: "6a2f8b0b...")
    var mealType: String      // "아침", "점심", "저녁" 등
    var foodName: String
    var amount: Double        // String -> Double 로 변경 (예: 1.0, 250.0)
    var calories: Double      // calorie -> calories 로 이름 변경
    var carbs: Double         // carb -> carbs 로 이름 변경
    var protein: Double
    var fat: Double
    var imageUrl: String?
    var eatenAt: String       // "2026-06-15T12:30:00" 형태
    var createdAt: String?
    
    // UI 프로그래스 바를 위한 연산 프로퍼티
    var carbRatio: Double { min(carbs / 150.0, 1.0) }
    var proteinRatio: Double { min(protein / 75.0, 1.0) }
    var fatRatio: Double { min(fat / 50.0, 1.0) }
}

// 🌟 텍스트 검색 API(Spoonacular) 결과를 받기 위한 전용 구조체 추가
struct FoodSearchResult: Codable, Identifiable {
    var id: UUID { UUID() }
    let foodName: String
    let imageUrl: String?
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
}

// 💡 파이썬 서버의 최종 AI 분석 결과를 매핑하기 위한 모델
struct AIAnalysisResponse: Codable {
    let status: String
    let spoonDetected: Bool?
    let results: [AIArticleResult]
}

struct AIArticleResult: Codable, Hashable {
    let foodName: String
    let weightG: Double
    let caloriesKcal: Double
    let shapeType: String
    // 💡 [추가] 서버가 "숟가락 미인식 -> 기본값 추정"일 때 보내는 안내 문구.
    // 정상적으로 정밀 계산됐을 땐 서버 응답에 이 키 자체가 없으므로 옵셔널로 둠.
    let message: String?
}
