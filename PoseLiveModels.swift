//
//  PoseLiveModels.swift
//  TipsyCut
//
//  pose-server(WebSocket)와 Spring Boot(REST) 응답을 매핑하는 모델 모음.
//

import Foundation

// MARK: - pose-server 웹소켓 메시지

enum PoseStatus: String, Decodable {
    case noPerson = "no_person"
    case collecting
    case analyzing
    case uncertain
    case error
}

struct PoseCheckItem: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let ok: Bool
    let desc: String
    let weight: Int
}

struct LiveAnalysisMessage: Decodable {
    let status: PoseStatus
    let buffered: Int?
    let exercise: String?
    let phase: String?
    let phaseLabel: String?
    let score: Int?
    let results: [PoseCheckItem]?
    let message: String?   // status == .error / .uncertain 일 때 안내 문구

    enum CodingKeys: String, CodingKey {
        case status, buffered, exercise, phase, results, message, score
        case phaseLabel = "phase_label"
    }
}

struct ExerciseItemScore: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let score: Int
    let weight: Int
}

struct ExerciseFeedback: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let text: String
}

/// 세션 종료("finish") 시 pose-server가 한 번 보내주는 전체 요약
struct ExerciseSessionSummary: Decodable {
    let status: String
    let exercise: String?
    let avgScore: Int
    let durationMin: Int
    let durationSec: Double
    let repCount: Int?
    let holdSeconds: Double?
    let itemScores: [ExerciseItemScore]
    let feedbacks: [ExerciseFeedback]
}

/// 메시지 종류(status)만 먼저 가볍게 읽어서 어떤 타입으로 디코딩할지 정하기 위함
struct StatusOnly: Decodable {
    let status: String
}

// MARK: - Spring Boot REST 응답

struct ApiResponse<T: Decodable>: Decodable {
    let data: T?
    let message: String
    let success: Bool
}

struct ExerciseLogResponse: Decodable {
    let exerciseLogId: Int
    let exerciseName: String
    let durationMin: Int?
    let sets: Int?
    let reps: Int?
    let caloriesBurned: Int?
    let score: Double?
    let feedback: String?
    let exercisedAt: String
    let createdAt: String
}

/// POST /api/exercises/logs 요청 바디
struct ExerciseLogCreateRequest: Encodable {
    let exerciseName: String
    let durationMin: Int
    var sets: Int?
    var reps: Int?
    var caloriesBurned: Int?
    var score: Double?
    var feedback: String?
    let exercisedAt: String   // ISO-8601
}
