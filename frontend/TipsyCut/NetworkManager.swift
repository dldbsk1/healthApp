import Foundation
import UIKit // 🌟 UIImage를 사용하기 위해 꼭 필요합니다!

// 🌟 백엔드에서 주는 { totalCalories: 478.3, logs: [...] } 형태의 응답을 받기 위한 껍데기
struct DailyDietResponse: Codable {
    let totalCalories: Double
    let logs: [DietLog]
}

class NetworkManager {
    // 앱 전체에서 단 하나의 심부름꾼만 쓰도록 싱글톤(Singleton)으로 만듭니다.
    static let shared = NetworkManager()
    
    // 🚨 자바 Spring Boot 메인 서버(Cloudflare 터널) 주소로 변경하세요!
    //    · 포트(:8080)는 붙이지 않습니다. trycloudflare 주소는 https(443)로 접속하고, 8080 은 터널이 연결해 주는 서버 PC 쪽 포트입니다.
    //    · 이 주소는 cloudflared 를 다시 켤 때마다 바뀝니다. 바뀌면 이 줄(baseURL)만 수정하세요.
    let baseURL = "https://reputation-saskatchewan-willing-taxes.trycloudflare.com/api"
    
    private init() {} // 외부에서 함부로 생성하지 못하게 막음
    
    // 1️⃣ 음식 검색 API (GET)
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // 💡 로그인한 사용자의 userId도 함께 보내서, 이 사용자가 직접 추가한 "내 메뉴"도 검색되게 함
        // 저장할 때 쓰는 기본값과 똑같이 맞춰서, 저장한 "내 메뉴"가 검색에서 빠지지 않게 함
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/food/search?query=\(encodedQuery)&userId=\(encodedUserId)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        let (data, _) = try await URLSession.shared.data(for: request)
        print("📦 [음식 검색] 서버가 보낸 원본 데이터: \(String(data: data, encoding: .utf8) ?? "없음")")
        return try JSONDecoder().decode([FoodSearchResult].self, from: data)
    }
    
    // 2️⃣ 식단 저장 API (POST)
    func saveDietLog(log: DietLog) async throws {
        let urlString = "\(baseURL)/diet/log"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 🌟 혹시 모를 ngrok 차단 방지 암호
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        request.httpBody = try JSONEncoder().encode(log)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            // 🚨 범인을 잡기 위한 핵심 출력 코드!
            print("📡 백엔드 응답 상태 코드: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("✅ 서버 저장 성공! 응답: \(String(data: data, encoding: .utf8) ?? "")")
            } else {
                print("❌ 서버 저장 실패! 서버 메시지: \(String(data: data, encoding: .utf8) ?? "")")
                throw URLError(.badServerResponse)   // 💡 실패를 호출한 쪽에 알림 (성공으로 오해하지 않도록)
            }
        }
    }
    
    // 3️⃣ 하루 식단 목록 및 총 칼로리 조회 API (GET) 최종 완성본!
    func fetchDailyDiet(userId: String, date: String) async throws -> DailyDietResponse {
        let urlString = "\(baseURL)/diet/log?userId=\(userId)&date=\(date)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        print("📦 [식단 불러오기] 서버가 보낸 원본 데이터: \(String(data: data, encoding: .utf8) ?? "없음")")
        
        // 🌟 1. 백엔드가 보내준 배열 데이터를 Swift 배열로 예쁘게 변환합니다.
        let logs = try JSONDecoder().decode([DietLog].self, from: data)
        
        // 🌟 2. 스위프트가 직접 모든 음식의 칼로리를 더해서 총 칼로리를 계산합니다!
        let calculatedTotalCalories = logs.reduce(0) { $0 + $1.calories }
        
        // 🌟 3. UI 화면이 기다리고 있는 껍데기(DailyDietResponse)에 담아서 리턴!
        return DailyDietResponse(totalCalories: calculatedTotalCalories, logs: logs)
    }
    
    // 4️⃣ AI 사진 분석 요청 API (POST - Multipart Form)
    func uploadImageForAnalysis(image: UIImage) async throws -> String {
        // ⚠️ 이 함수는 현재 어디서도 쓰이지 않습니다. 앱은 AI 서버를 직접 부르지 않고 백엔드(/food/upload)를 거칩니다.
        //    아래 주소(예전 ngrok)는 그대로 두었으니, 이 함수를 다시 쓰려면 음식 AI 서버 주소로 바꾸세요.
        let aiBaseURL = "https://vitality-declared-askew.ngrok-free.dev"
        let urlString = "\(aiBaseURL)/analyze-food/" // FastAPI의 엔드포인트
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"food_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📸 AI 서버 응답 상태 코드: \(httpResponse.statusCode)")
        }
        
        if let resultString = String(data: data, encoding: .utf8) {
            print("📦 AI 분석 결과 원본: \(resultString)")
            return resultString
        } else {
            throw URLError(.badServerResponse)
        }
    }
    
    // 5️⃣ [ARKit 전용] 이미지 및 실측 두께 데이터 전송 API (POST - Multipart Form)
    func uploadImageWithARData(image: UIImage, thickness: Double) async throws -> AIAnalysisResponse {
        
        // 💡 파이썬 직접 연결을 지우고, 자바 스프링부트 API 경로로 전송!
        let urlString = "\(baseURL)/food/upload"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body = Data()
        
        // 1. 이미지 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"ar_food_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 2. 두께 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"thickness\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(thickness)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        print("📦 [AI 분석] 서버가 보낸 원본 데이터: \(String(data: data, encoding: .utf8) ?? "없음")")
        
        // 🧠 파이썬 snake_case 응답을 Swift camelCase 규칙으로 예쁘게 파싱
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(AIAnalysisResponse.self, from: data)
    }
    
    // 6️⃣ 🌟 [새로 추가됨] 식단 타입에 맞는 랜덤 메뉴 추천 API (GET)
        func fetchRandomDietMenu(type: String, userId: String) async throws -> DietLog { // 💡 파라미터에 userId 추가[cite: 36]
            // 기존 baseURL에 맞춰 엔드포인트 구성 (URL 끝에 userId 쿼리 스트링 결합)[cite: 36]
            let urlString = "\(baseURL)/recommendation/random?dietType=\(type)&userId=\(userId)"
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL) //[cite: 36]
            }
            
            var request = URLRequest(url: url) //[cite: 36]
            request.httpMethod = "GET" //[cite: 36]
            
            // 💡 다른 API와 동일하게 ngrok 차단 방지 헤더 필수 추가[cite: 36]
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning") //[cite: 36]
            
            let (data, response) = try await URLSession.shared.data(for: request) //[cite: 36]
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { //[cite: 36]
                print("❌ 추천 서버 응답 에러") //[cite: 36]
                throw URLError(.badServerResponse) //[cite: 36]
            }
            
            // Spring Boot가 반환한 JSON을 DietLog 모델로 디코딩하여 반환[cite: 36]
            let decodedLog = try JSONDecoder().decode(DietLog.self, from: data) //[cite: 36]
            return decodedLog //[cite: 36]
        }
        
        // 7️⃣ 주류별 추천 메뉴 페어링 API
        func fetchDrinkPairing(drink: String, userId: String) async throws -> DietLog { // 💡 파라미터에 userId 추가[cite: 36]
            let encodedDrink = drink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "" //[cite: 36]
            // URL 끝에 userId 쿼리 스트링 결합[cite: 36]
            let urlString = "\(baseURL)/recommendation/pairing?drink=\(encodedDrink)&userId=\(userId)"
            
            guard let url = URL(string: urlString) else { throw URLError(.badURL) } //[cite: 36]
            
            var request = URLRequest(url: url) //[cite: 36]
            request.httpMethod = "GET" //[cite: 36]
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning") //[cite: 36]
            
            // 🌟 [핵심 추가] iOS가 예전 결과를 기억하지 않고 무조건 서버에 새로 받아오도록 강제![cite: 36]
            request.cachePolicy = .reloadIgnoringLocalCacheData //[cite: 36]
            
            let (data, response) = try await URLSession.shared.data(for: request) //[cite: 36]
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { //[cite: 36]
                throw URLError(.badServerResponse) //[cite: 36]
            }
            
            return try JSONDecoder().decode(DietLog.self, from: data) //[cite: 36]
        }

    // 8️⃣ 🌟 [새로 추가됨] 회원가입 API 호출 함수
    func signUpUser(userData: UserSignUpData) async throws -> Bool {
        let urlString = "\(baseURL)/users/signup" // 백엔드 컨트롤러 주소
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(userData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 회원가입 응답 상태 코드: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("✅ 회원가입 성공!")
                return true
            } else {
                print("❌ 회원가입 실패! 서버 메시지: \(String(data: data, encoding: .utf8) ?? "")")
                return false
            }
        }
        return false
    }
    func loginUser(loginData: UserLoginData) async throws -> Int? {
            let urlString = "\(baseURL)/users/login"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(loginData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // 💡 로그인 성공 시, 백엔드가 보내준 유저 정보에서 권장 칼로리만 쏙 뽑아냅니다!
                    let userInfo = try JSONDecoder().decode(UserLoginResponse.self, from: data)
                    return userInfo.recommendedCalories
                } else {
                    print("❌ 로그인 실패! 서버 메시지: \(String(data: data, encoding: .utf8) ?? "")")
                    return nil
                }
            }
            return nil
        }
    // 🌟 주량 기록을 백엔드로 전송하는 함수
        func saveDrinkLog(data: [String: Any]) async throws -> Bool {
            let urlString = "\(baseURL)/drinks/log"
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            
            // 딕셔너리를 JSON 데이터로 변환
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ 주량 기록 성공!")
                return true
            } else {
                print("❌ 주량 기록 실패")
                return false
            }
        }
    // NetworkManager.swift 내부 클래스 함수로 추가 (기존 함수들 아래)
        // 9️⃣ 🌟 [새로 추가됨] 사용자 프로필 업데이트 API
        func updateProfile(userData: UserSignUpData) async throws -> Bool {
            let urlString = "\(baseURL)/users/update" // 백엔드 업데이트 컨트롤러 주소 (추후 구현 예정)
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT" // 수정을 의미하는 PUT 메서드 사용
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(userData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 프로필 업데이트 응답 상태 코드: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    print("✅ 프로필 업데이트 성공!")
                    return true
                } else {
                    print("❌ 프로필 업데이트 실패! 서버 메시지: \(String(data: data, encoding: .utf8) ?? "")")
                    return false
                }
            }
            return false
        }
    // 🔟 식단 기록 수정 API (PUT)
    func updateDietLog(_ log: DietLog) async throws {
        guard let id = log._id else { throw URLError(.badURL) }
        guard let url = URL(string: "\(baseURL)/diet/log/\(id)") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = try JSONEncoder().encode(log)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            print("❌ 식단 수정 실패: \(String(data: data, encoding: .utf8) ?? "")")
            throw URLError(.badServerResponse)
        }
    }
    
    // 1️⃣1️⃣ 식단 기록 삭제 API (DELETE) — userId로 본인 기록인지 서버가 확인
    func deleteDietLog(id: String, userId: String) async throws {
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
        guard let url = URL(string: "\(baseURL)/diet/log/\(id)?userId=\(encodedUserId)") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            print("❌ 식단 삭제 실패: \(String(data: data, encoding: .utf8) ?? "")")
            throw URLError(.badServerResponse)
        }
    }
    
    // 1️⃣2️⃣ 내 메뉴 저장 API (POST) — userId별로 저장되어 다른 사용자에게는 보이지 않음
    func saveUserMenu(_ menu: UserMenuRequest) async throws {
        guard let url = URL(string: "\(baseURL)/user-menus") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = try JSONEncoder().encode(menu)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            print("❌ 내 메뉴 저장 실패: \(String(data: data, encoding: .utf8) ?? "")")
            throw URLError(.badServerResponse)
        }
    }
    
    // 1️⃣3️⃣ 내 메뉴 삭제 API (DELETE)
    func deleteUserMenu(userId: String, foodName: String) async throws {
        guard var components = URLComponents(string: "\(baseURL)/user-menus") else { throw URLError(.badURL) }
        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "foodName", value: foodName)
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            print("❌ 내 메뉴 삭제 실패: \(String(data: data, encoding: .utf8) ?? "")")
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchUserProfile(email: String) async throws -> UserProfileResponse? {
        let urlString = "\(baseURL)/users/profile?email=\(email)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(UserProfileResponse.self, from: data)
        }
        return nil
    }
    
    }



// 🌟 내 메뉴 저장 요청 (칼로리·탄단지는 1인분 기준, 입력하지 않은 값은 비워서 보냄)
struct UserMenuRequest: Codable {
    var userId: String
    var foodName: String
    var calories: Double?
    var carbs: Double?
    var protein: Double?
    var fat: Double?
}

// 🌟 [새로 추가됨] 보낼 사용자 정보 구조체 정의 (클래스 바깥에 작성)
struct UserSignUpData: Codable {
    var email: String
    var password: String
    var gender: String
    var age: Int
    var height: Double
    var weight: Double
    var activityLevel: String
    var goal: String
    var dietPreference: String
    var recommendedCalories: Int
    var nickname: String? = nil   // 닉네임(선택). nil이면 서버로 보내지 않음
}

struct UserLoginData: Codable {
    var email: String
    var password: String
}

struct UserLoginResponse: Codable {
    var recommendedCalories: Int
}

struct UserProfileResponse: Codable {
    let email: String
    let gender: String
    let age: Int
    let height: Double
    let weight: Double
    let activityLevel: String
    let goal: String
    let dietPreference: String
    let recommendedCalories: Int
    let nickname: String?   // 닉네임(없을 수 있음)
}

// MARK: - 소통(Social) 화면용 네트워크 코드 (껍데기)
// 소통 탭(SocialView / SocialCalendarView / SocialOneDayView)이 컴파일되도록 남겨 둔 코드입니다.
// - 소통 기능은 담당 팀원이 구현합니다. 구현할 때는 이 MARK 구간(extension + SocialPostDTO)만 교체하면 됩니다.
// - 아래 함수들은 /social/... 주소를 부르는데, 합친 백엔드에는 아직 이 주소가 없습니다(사진 기능은 /api/photos/...).
//   그래서 지금은 서버가 404 를 주고, 화면은 "밤 9시에 공개돼요"(잠금) / 빈 캘린더 상태로 보입니다. (앱이 죽지는 않습니다)
// - 화면이 쓰는 함수 이름·모델(SocialPostDTO)을 바꾸면 소통 화면 3개도 같이 고쳐야 합니다.

extension NetworkManager {
    // 🌟 [추가됨] 1. 내 사진 업로드 API
    func uploadSocialPost(userId: String, image: UIImage) async throws -> Bool {
        // 실제 운영 시에는 이미지를 S3 등에 올리고 URL을 받아야 하지만,
        // 현재 백엔드 구조에 맞춰 더미 이미지 URL을 전송합니다.
        let urlString = "\(baseURL)/social/upload"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        // 💡 임시 더미 URL 세팅
        let dummyImageUrl = "https://picsum.photos/300/300"
        let body = ["userId": userId, "imageUrl": dummyImageUrl]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return true
        }
        return false
    }
    
    // 🌟 [추가됨] 2. 밤 9시 랜덤 사진 받기 API
    func fetchReceivedPhoto(userId: String) async throws -> SocialPostDTO? {
        let urlString = "\(baseURL)/social/received?userId=\(userId)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(SocialPostDTO.self, from: data)
        }
        return nil
    }
    
    // 🌟 [추가됨] 3. 리액션 보내기 API
    func sendReaction(postId: String, emoji: String) async throws -> Bool {
        let urlString = "\(baseURL)/social/reaction"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body = ["postId": postId, "emoji": emoji]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return true
        }
        return false
    }
    
    // 🌟 [추가됨] 4. 내 캘린더 히스토리 조회 API
    func fetchSocialCalendar(userId: String) async throws -> [SocialPostDTO] {
        let urlString = "\(baseURL)/social/calendar?userId=\(userId)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try JSONDecoder().decode([SocialPostDTO].self, from: data)
        }
        return []
    }
}

// 🌟 [새로 추가됨] SNS 관련 데이터 모델 구조체
struct SocialPostDTO: Codable {
    let id: String
    let userId: String
    let imageUrl: String
    let targetDate: String
    let reactions: [String: Int]
}
