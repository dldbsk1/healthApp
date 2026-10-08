//
//  PhotoModels.swift
//  TipsyCut
//
//  SNS탭(PhotoController) 응답 매핑 모델.
//  ApiResponse<T> 는 PoseLiveModels.swift에 이미 정의되어 있으므로 여기선 재사용만 함.
//

import Foundation

enum PhotoReactionType: String, Codable, CaseIterable {
    case heart = "HEART"
    case love = "LOVE"
    case muscle = "MUSCLE"
    case sweat = "SWEAT"
    case fire = "FIRE"

    /// 화면에 보여줄 이모지. 백엔드 enum과 1:1 매칭만 시켜둔 것 (실제 이모지 모양은 UI 쪽 결정).
    var emoji: String {
        switch self {
        case .heart: return "❤️"
        case .love: return "😍"
        case .muscle: return "💪"
        case .sweat: return "👏"
        case .fire: return "🔥"
        }
    }
}

struct PhotoLogResponse: Decodable {
    let photoId: Int
    let imageUrl: String
    let category: String?
    let memo: String?
    let logDate: String
    let createdAt: String
}

struct PhotoReactionResponse: Decodable, Identifiable {
    var id: String { "\(reactorId)-\(reactionType.rawValue)-\(createdAt)" }
    let reactorId: Int
    let reactorNickname: String
    let reactionType: PhotoReactionType
    let createdAt: String
}

struct ReceivedPhotoResponse: Decodable {
    let locked: Bool
    let shareId: Int?
    let imageUrl: String?
    let uploaderNickname: String?
    let reactions: [PhotoReactionResponse]

    enum CodingKeys: String, CodingKey {
        case locked, shareId, imageUrl, uploaderNickname, reactions
    }

    /// 서버가 잠긴 상태에서 reactions 등을 생략해도 receivedPhoto 전체가 nil 이 되지 않도록
    /// 필드별로 관대하게 읽는다.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        locked = (try? c.decodeIfPresent(Bool.self, forKey: .locked)) ?? false
        shareId = try? c.decodeIfPresent(Int.self, forKey: .shareId)
        imageUrl = try? c.decodeIfPresent(String.self, forKey: .imageUrl)
        uploaderNickname = try? c.decodeIfPresent(String.self, forKey: .uploaderNickname)
        reactions = (try? c.decodeIfPresent([PhotoReactionResponse].self, forKey: .reactions)) ?? []
    }
}

struct CalendarDayResponse: Decodable, Identifiable {
    var id: String { date }
    let date: String          // "yyyy-MM-dd"
    let thumbnailUrl: String
}

struct PhotoDetailResponse: Decodable {
    let photoId: Int
    let imageUrl: String
    let memo: String?
    let logDate: String
    let reactions: [PhotoReactionResponse]

    enum CodingKeys: String, CodingKey {
        case photoId, imageUrl, memo, logDate, reactions
    }

    /// 리액션 목록에 이상한 값이 있어도 사진 자체는 읽히도록 reactions 만 관대하게 처리
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        photoId = try c.decode(Int.self, forKey: .photoId)
        imageUrl = try c.decode(String.self, forKey: .imageUrl)
        memo = try? c.decodeIfPresent(String.self, forKey: .memo)
        logDate = (try? c.decode(String.self, forKey: .logDate)) ?? ""
        reactions = (try? c.decodeIfPresent([PhotoReactionResponse].self, forKey: .reactions)) ?? []
    }
}

struct ReactionRequestBody: Encodable {
    let reactionType: PhotoReactionType
}
