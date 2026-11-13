//
//  PoseWebSocketClient.swift
//  TipsyCut
//
//  pose-server(ws://.../ws/exercise-live?exercise=...)와 통신.
//  운동 종류는 연결 시점에 이미 확정되어 있으므로(사용자가 미리 선택),
//  서버도 LSTM 분류 없이 그 이름을 그대로 사용한다.
//

import Foundation
import UIKit
import Combine

final class PoseWebSocketClient: NSObject, ObservableObject {

    @Published private(set) var isConnected = false
    @Published private(set) var status: PoseStatus?
    @Published private(set) var phaseLabel: String?
    @Published private(set) var currentScore: Int = 0
    @Published private(set) var checkItems: [PoseCheckItem] = []
    @Published private(set) var uncertainMessage: String?
    @Published private(set) var errorMessage: String?

    @Published private(set) var finalSummary: ExerciseSessionSummary?

    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let serverURL: URL
    private let minSendInterval: TimeInterval = 0.1
    private var lastSentAt: Date = .distantPast
    private var pendingFinishCompletion: ((ExerciseSessionSummary?) -> Void)?

    /// - Parameter exerciseBackendName: pose_rules.py의 EXERCISE_RULES 키와 정확히 같은 이름 (예: "런지")
    init(exerciseBackendName: String) {
        let urlString = "\(AppConfig.poseServerWebSocketBase)/ws/exercise-live?exercise=\(exerciseBackendName)"
        // 한글 등 쿼리 인코딩
        let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
        self.serverURL = URL(string: encoded)!
        self.session = URLSession(configuration: .default)
        super.init()
    }

    func connect() {
        guard webSocketTask == nil else { return }
        let task = session.webSocketTask(with: serverURL)
        webSocketTask = task
        task.resume()
        isConnected = true
        finalSummary = nil
        listen()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    /// "운동 완료" 시 호출. 서버에 "finish"를 보내고 세션 요약을 받으면 completion으로 전달.
    func finishSession(completion: @escaping (ExerciseSessionSummary?) -> Void) {
        guard isConnected else {
            completion(nil)
            return
        }
        pendingFinishCompletion = completion
        webSocketTask?.send(.string("finish")) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "종료 요청 실패: \(error.localizedDescription)"
                    self?.pendingFinishCompletion?(nil)
                    self?.pendingFinishCompletion = nil
                }
            }
        }
    }

    func sendFrame(_ image: UIImage) {
        guard isConnected else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSentAt) >= minSendInterval else { return }
        lastSentAt = now

        guard let jpegData = image.jpegData(compressionQuality: 0.6) else { return }
        webSocketTask?.send(.data(jpegData)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "전송 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "연결 오류: \(error.localizedDescription)"
                    self.isConnected = false
                }
                return

            case .success(let message):
                if case let .string(text) = message, let data = text.data(using: .utf8) {
                    self.handle(data)
                }
            }

            if self.pendingFinishCompletion == nil {
                self.listen()
            }
        }
    }

    private func handle(_ data: Data) {
        guard let statusOnly = try? JSONDecoder().decode(StatusOnly.self, from: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "응답 파싱 실패"
            }
            return
        }

        if statusOnly.status == "session_summary" {
            let summary = try? JSONDecoder().decode(ExerciseSessionSummary.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.finalSummary = summary
                self.pendingFinishCompletion?(summary)
                self.pendingFinishCompletion = nil
                self.isConnected = false
                self.webSocketTask = nil
            }
            return
        }

        do {
            let decoded = try JSONDecoder().decode(LiveAnalysisMessage.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.status = decoded.status
                self.phaseLabel = decoded.phaseLabel
                self.checkItems = decoded.results ?? []
                if let score = decoded.score { self.currentScore = score }
                self.uncertainMessage = (decoded.status == .uncertain) ? decoded.message : nil
                if decoded.status == .error { self.errorMessage = decoded.message }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "응답 파싱 실패: \(error.localizedDescription)"
            }
        }
    }
}
