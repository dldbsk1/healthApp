//
//  PhotoAPIClient.swift
//  TipsyCut
//
//  PhotoController(Spring Boot) 호출을 한 곳에 모아둠.
//

import Foundation
import SwiftUI
import UIKit


final class PhotoAPIClient {

    static let shared = PhotoAPIClient()
    private init() {}

    private var baseURL: String { AppConfig.springBootBaseURL }
    private var userId: Int { AppConfig.temporaryUserId }

    // MARK: - 사진 업로드

    func upload(image: UIImage, category: String? = nil, memo: String? = nil,
                completion: @escaping (PhotoLogResponse?) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = "\(cleanBaseURL)/api/photos?userId=\(userId)"

        guard let url = URL(string: urlString) else {
            print("❌ [URL 생성 실패] 잘못된 URL 문자열입니다 -> '\(urlString)'")
            completion(nil)
            return
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ [JPEG 변환 실패] 이미지 변환에 실패했습니다.")
            completion(nil)
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(boundary: boundary, imageData: jpegData,
                                             category: category, memo: memo)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [Upload Error] 네트워크 연결 실패:", error.localizedDescription)
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [Upload Response] HTTP Status Code:", httpResponse.statusCode)
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📄 [Upload Response] Body:", responseString)
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ApiResponse<PhotoLogResponse>.self, from: data)
                DispatchQueue.main.async { completion(decoded.data) }
            } catch {
                print("⚠️ [Upload Error] JSON 디코딩 실패 (DTO 구조 확인 필요):", error)
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }

    private func makeMultipartBody(boundary: String, imageData: Data,
                                   category: String?, memo: String?) -> Data {
        var body = Data()

        func appendString(_ string: String) {
            if let data = string.data(using: .utf8) {
                body.append(data)
            }
        }

        func appendField(name: String, value: String) {
            appendString("--\(boundary)\r\n")
            appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            appendString("\(value)\r\n")
        }

        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n")
        appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        appendString("\r\n")

        if let category = category { appendField(name: "category", value: category) }
        if let memo = memo { appendField(name: "memo", value: memo) }

        appendString("--\(boundary)--\r\n")
        return body
    }

    // MARK: - 내가 오늘 올린 사진 조회 (추가됨)

    /// 오늘 내가 올린 사진 상세 (imageUrl + 이 사진에 상대가 보낸 리액션). 없으면 nil.
    /// GET /api/photos?userId&date → ApiResponse<PhotoDetailResponse>
    /// (오늘 올린 사진이 없으면 서버가 EntityNotFoundException 을 내므로 nil 이 정상)
    func fetchMyTodayPhoto(completion: @escaping (PhotoDetailResponse?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos?userId=\(userId)&date=\(todayString)") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in

            var detail: PhotoDetailResponse? = nil

            if let data = data, error == nil {
                if let decoded = try? JSONDecoder().decode(ApiResponse<PhotoDetailResponse>.self, from: data) {
                    detail = decoded.data
                } else {
                    print("⚠️ [MyTodayPhoto] 오늘 사진 응답을 읽지 못했거나 사진이 없음: \(String(data: data, encoding: .utf8) ?? "-")")
                }
            }

            DispatchQueue.main.async { completion(detail) }
        }.resume()
    }

    // MARK: - 오늘 받은 사진

    func fetchReceivedToday(completion: @escaping (ReceivedPhotoResponse?) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos/received/today?userId=\(userId)") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [ReceivedToday Error]:", error.localizedDescription)
            }
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ApiResponse<ReceivedPhotoResponse>.self, from: data)
                let received = decoded.data
                print("📥 [ReceivedToday] userId=\(self.userId) locked=\(received?.locked.description ?? "nil") shareId=\(received?.shareId.map(String.init) ?? "nil") imageUrl=\(received?.imageUrl ?? "nil")")
                DispatchQueue.main.async { completion(received) }
            } catch {
                print("❌ [ReceivedToday] 디코딩 실패: \(error)")
                print("   원본 응답: \(String(data: data, encoding: .utf8) ?? "-")")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }

    // MARK: - 리액션 보내기

    // MARK: - 받은 사진 열기 (서버의 잠금 해제)

    /// 서버(PhotoService.openReceived)에서 받은 사진의 잠금을 풀고 imageUrl 이 담긴 응답을 받는다.
    /// 잠금 해제는 서버에 기록되므로 이후 /received/today 조회도 unlocked 로 내려온다.
    /// PhotoController: @PostMapping("/shares/{shareId}/open") — POST /api/photos/shares/{shareId}/open?userId=
    func openReceived(shareId: Int, completion: @escaping (ReceivedPhotoResponse?) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos/shares/\(shareId)/open?userId=\(userId)") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in

            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            guard let data = data, error == nil else {
                print("❌ [OpenReceived] 요청 실패: \(error?.localizedDescription ?? "-")")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ApiResponse<ReceivedPhotoResponse>.self, from: data)
                print("🔓 [OpenReceived] status=\(status) locked=\(decoded.data?.locked.description ?? "nil") imageUrl=\(decoded.data?.imageUrl ?? "nil")")
                DispatchQueue.main.async { completion(decoded.data) }
            } catch {
                // 404 → 이미 사라졌거나 내 사진이 아닌 shareId (EntityNotFoundException)
                print("❌ [OpenReceived] status=\(status) 디코딩 실패: \(error)")
                print("   원본 응답: \(String(data: data, encoding: .utf8) ?? "-")")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }

    func sendReaction(shareId: Int, type: PhotoReactionType, completion: @escaping (Bool) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos/shares/\(shareId)/reactions?userId=\(userId)") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(ReactionRequestBody(reactionType: type))

        URLSession.shared.dataTask(with: request) { _, response, error in
            let ok = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(ok) }
        }.resume()
    }

    // MARK: - 캘린더 (이번 달 사진 있는 날짜들)

    func fetchCalendar(year: Int, month: Int, completion: @escaping ([CalendarDayResponse]) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos/calendar?userId=\(userId)&year=\(year)&month=\(month)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let decoded = try? JSONDecoder().decode(ApiResponse<[CalendarDayResponse]>.self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            DispatchQueue.main.async { completion(decoded.data ?? []) }
        }.resume()
    }

    // MARK: - 날짜별 상세 (확대 + 리액션)

    func fetchDetail(dateString: String, completion: @escaping (PhotoDetailResponse?) -> Void) {
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(cleanBaseURL)/api/photos?userId=\(userId)&date=\(dateString)") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let decoded = try? JSONDecoder().decode(ApiResponse<PhotoDetailResponse>.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(decoded.data) }
        }.resume()
    }
}
