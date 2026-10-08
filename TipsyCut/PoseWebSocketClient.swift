//
//  PoseWebSocketClient.swift
//  TipsyCut
//
//  pose-server(ws://.../ws/exercise-live?exercise=...)와 통신.
//
//  운동 종류는 연결 시점에 이미 확정되어 있으므로(사용자가 미리 선택),
//  서버도 LSTM 분류 없이 그 이름을 그대로 사용한다.
//

import Foundation
import UIKit
import Combine

final class PoseWebSocketClient: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isConnected = false
    @Published private(set) var status: PoseStatus?
    @Published private(set) var phaseLabel: String?
    @Published private(set) var currentScore: Int = 0
    @Published private(set) var checkItems: [PoseCheckItem] = []
    @Published var keypoints: [CGPoint] = []
    @Published private(set) var uncertainMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var finalSummary: ExerciseSessionSummary?

    // MARK: - WebSocket

    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let serverURL: URL

    // 초당 약 10프레임
    private let minSendInterval: TimeInterval = 0.1
    private var lastSentAt: Date = .distantPast

    // 운동 종료 후 session_summary를 기다리기 위한 completion
    private var pendingFinishCompletion: ((ExerciseSessionSummary?) -> Void)?

    // 연결 확인용
    private var isConnecting = false

    // 카메라 큐(백그라운드)와 메인 스레드가 함께 만지는 값들 → 락으로 보호
    private let stateLock = NSLock()
    private var socketReady = false          // isConnected의 스레드 안전 사본
    private var awaitingReply = false        // 보낸 프레임의 응답을 기다리는 중
    private var lastFrameSize: CGSize = .zero // 마지막으로 보낸 프레임 크기(픽셀 좌표 보정용)
    private let replyTimeout: TimeInterval = 1.0

    // MARK: - Init

    /// - Parameter exerciseBackendName:
    /// pose_rules.py의 EXERCISE_RULES 키와 정확히 같은 이름
    /// 예: "런지"
    init(exerciseBackendName: String) {

        let rawBase = AppConfig.poseServerWebSocketBase

        // http:// -> ws://
        // https:// -> wss://
        var wsBase = rawBase

        if wsBase.hasPrefix("https://") {
            wsBase = wsBase.replacingOccurrences(
                of: "https://",
                with: "wss://"
            )
        } else if wsBase.hasPrefix("http://") {
            wsBase = wsBase.replacingOccurrences(
                of: "http://",
                with: "ws://"
            )
        }

        // 마지막 "/"가 있으면 제거
        while wsBase.hasSuffix("/") {
            wsBase.removeLast()
        }

        let urlString =
            "\(wsBase)/ws/exercise-live?exercise=\(exerciseBackendName)"

        // 한글 운동명 등 쿼리 인코딩
        let encoded =
            urlString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? urlString

        guard let url = URL(string: encoded) else {
            fatalError("Invalid WebSocket URL: \(encoded)")
        }

        self.serverURL = url
        self.session = URLSession(configuration: .default)

        super.init()

        print("======================================")
        print("🔌 Pose WebSocket Client 생성")
        print("🔌 WebSocket URL: \(serverURL.absoluteString)")
        print("======================================")
    }

    // MARK: - Connect

    func connect() {

        // 이미 연결 중이거나 연결되어 있으면 중복 연결하지 않음
        guard webSocketTask == nil, !isConnecting else {
            print("⚠️ WebSocket: 이미 연결 중이거나 연결되어 있습니다.")
            return
        }

        isConnecting = true

        DispatchQueue.main.async { [weak self] in
            self?.setConnected(false)
            self?.errorMessage = nil
            self?.finalSummary = nil
        }

        print("🔌 WebSocket 연결 시도")
        print("🔌 URL: \(serverURL.absoluteString)")

        let task = session.webSocketTask(with: serverURL)

        webSocketTask = task

        task.resume()

        // 서버에서 들어오는 메시지 수신 시작
        listen()

        // 실제 연결 여부를 ping으로 확인
        task.sendPing { [weak self] error in

            guard let self = self else {
                return
            }

            DispatchQueue.main.async {

                self.isConnecting = false

                if let error = error {

                    print("❌ WebSocket 연결 실패")

                    self.setConnected(false)
                    self.errorMessage =
                        "소켓 연결 실패: \(self.describe(error))"

                    self.webSocketTask?.cancel(
                        with: .abnormalClosure,
                        reason: nil
                    )

                    self.webSocketTask = nil

                } else {

                    print("✅ WebSocket 연결 성공")

                    self.setConnected(true)
                    self.errorMessage = nil
                }
            }
        }
    }

    // MARK: - Disconnect

    func disconnect() {

        print("🔌 WebSocket 연결 종료")

        webSocketTask?.cancel(
            with: .normalClosure,
            reason: nil
        )

        webSocketTask = nil

        DispatchQueue.main.async { [weak self] in
            self?.setConnected(false)
            self?.isConnecting = false
        }
    }

    // MARK: - Finish Session

    /// "운동 완료" 시 호출.
    /// 서버에 "finish"를 보내고
    /// session_summary를 받으면 completion으로 전달.
    func finishSession(
        completion: @escaping (ExerciseSessionSummary?) -> Void
    ) {

        guard let task = webSocketTask else {

            print("⚠️ finishSession: WebSocket task가 없습니다.")

            completion(nil)
            return
        }

        guard isConnected else {

            print("⚠️ finishSession: WebSocket이 연결되어 있지 않습니다.")

            completion(nil)
            return
        }

        print("🏁 운동 종료 요청 전송")

        pendingFinishCompletion = completion

        task.send(.string("finish")) { [weak self] error in

            guard let self = self else {
                return
            }

            DispatchQueue.main.async {

                if let error = error {

                    print("❌ 운동 종료 요청 실패")
                    print("❌ \(error.localizedDescription)")

                    self.errorMessage =
                        "종료 요청 실패: \(error.localizedDescription)"

                    self.pendingFinishCompletion?(nil)
                    self.pendingFinishCompletion = nil

                } else {

                    print("✅ finish 메시지 전송 완료")
                }
            }
        }
    }

    // MARK: - Send Frame

    /// 지금 프레임을 보내도 되는지 확인하고, 되면 슬롯을 예약한다.
    /// - 연결 안 됨 / 전송 간격 미달 / 직전 프레임 응답 대기 중이면 false
    /// - 응답을 기다리지 않고 계속 보내면 터널 구간에서 프레임이 쌓여
    ///   스켈레톤이 점점 늦게 따라오므로 한 번에 한 프레임만 보낸다.
    func reserveFrameSlot() -> Bool {

        stateLock.lock()
        defer { stateLock.unlock() }

        guard socketReady else {
            return false
        }

        let now = Date()

        guard now.timeIntervalSince(lastSentAt) >= minSendInterval else {
            return false
        }

        if awaitingReply,
           now.timeIntervalSince(lastSentAt) < replyTimeout {
            return false
        }

        awaitingReply = true
        lastSentAt = now
        return true
    }

    func releaseFrameSlot() {
        stateLock.lock()
        awaitingReply = false
        stateLock.unlock()
    }

    /// reserveFrameSlot()이 true였을 때만 호출
    func sendFrame(_ image: UIImage) {

        guard let jpegData = image.jpegData(
            compressionQuality: 0.6
        ) else {
            releaseFrameSlot()
            return
        }

        stateLock.lock()
        lastFrameSize = image.size
        stateLock.unlock()

        webSocketTask?.send(.data(jpegData)) { [weak self] error in

            guard let self = self, let error = error else {
                return
            }

            self.releaseFrameSlot()

            print("❌ 프레임 전송 실패: \(error.localizedDescription)")

            DispatchQueue.main.async {
                self.errorMessage =
                    "프레임 전송 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Connection State / Diagnostics

    private func setConnected(_ value: Bool) {
        stateLock.lock()
        socketReady = value
        if !value { awaitingReply = false }
        stateLock.unlock()

        isConnected = value
    }

    /// 에러 코드를 로그에 남기고, 사용자에게 보여줄 원인 힌트를 만든다.
    private func describe(_ error: Error) -> String {

        let ns = error as NSError

        print("❌ NSError domain=\(ns.domain) code=\(ns.code)")
        print("❌ userInfo=\(ns.userInfo)")

        let tlsCodes: Set<Int> = [
            NSURLErrorSecureConnectionFailed,          // -1200
            NSURLErrorServerCertificateHasBadDate,     // -1201
            NSURLErrorServerCertificateUntrusted,      // -1202
            NSURLErrorServerCertificateHasUnknownRoot, // -1203
            NSURLErrorServerCertificateNotYetValid,    // -1204
            NSURLErrorClientCertificateRejected        // -1205
        ]

        if ns.domain == NSURLErrorDomain, tlsCodes.contains(ns.code) {
            return "TLS 연결 실패(\(ns.code)). 터널 주소가 바뀌었거나 터널이 꺼졌는지 확인하세요. [\(serverURL.host ?? "")]"
        }

        if ns.domain == NSURLErrorDomain,
           ns.code == NSURLErrorCannotFindHost ||
           ns.code == NSURLErrorDNSLookupFailed {
            return "서버 주소를 찾을 수 없어요(\(ns.code)). 터널 주소를 확인하세요. [\(serverURL.host ?? "")]"
        }

        return "\(error.localizedDescription) (\(ns.code))"
    }

    // MARK: - Receive

    private func listen() {

        guard let task = webSocketTask else {
            return
        }

        task.receive { [weak self] result in

            guard let self = self else {
                return
            }

            switch result {

            case .failure(let error):

                print("❌ WebSocket 수신 오류")

                DispatchQueue.main.async {

                    self.setConnected(false)
                    self.isConnecting = false

                    self.errorMessage =
                        "소켓 연결 오류: \(self.describe(error))"

                    // 소켓이 끊기면 summary가 영영 안 오므로
                    // "운동을 정리하고 있어요..." 상태에서 멈추지 않도록 종료 처리
                    self.pendingFinishCompletion?(nil)
                    self.pendingFinishCompletion = nil
                }

                return

            case .success(let message):

                switch message {

                case .string(let text):

                    print("📩 WebSocket 메시지 수신")

                    if let data = text.data(using: .utf8) {
                        self.handle(data)
                    } else {

                        print("⚠️ 문자열을 Data로 변환하지 못했습니다.")

                        DispatchQueue.main.async {
                            self.errorMessage = "서버 응답을 읽을 수 없습니다."
                        }
                    }

                case .data(let data):

                    print("📩 WebSocket 바이너리 메시지 수신")

                    self.handle(data)

                @unknown default:

                    print("⚠️ 알 수 없는 WebSocket 메시지")
                }

                // 중요:
                // finish 요청 이후에도 session_summary가 올 때까지
                // 계속 receive를 유지해야 함.
                //
                // 기존 코드에서는 pendingFinishCompletion != nil이면
                // listen()을 다시 호출하지 않아서
                // 중간 메시지가 하나라도 들어오면 수신 루프가 멈출 수 있었음.
                if self.webSocketTask != nil {
                    self.listen()
                }
            }
        }
    }

    // MARK: - Handle Server Response

    private func handle(_ data: Data) {

        // 서버가 응답했으니 다음 프레임을 보낼 수 있다
        releaseFrameSlot()

        // 먼저 status만 확인
        guard let statusOnly = try? JSONDecoder().decode(
            StatusOnly.self,
            from: data
        ) else {

            print("❌ 서버 응답 StatusOnly 파싱 실패")

            if let rawText = String(data: data, encoding: .utf8) {
                print("📩 원본 서버 응답:")
                print(rawText)
            }

            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "서버 응답 파싱 실패"
            }

            return
        }

        // 원본 서버 응답 출력
        if let rawText = String(data: data, encoding: .utf8) {
            print("📩 서버 응답:")
            print(rawText)
        }

        // MARK: Session Summary

        if statusOnly.status == "session_summary" {

            // 실패하면 원인을 콘솔에 남긴다 (예전엔 try?로 삼켜서 결과가 전부 0으로 보였음)
            let summaryDecoder = JSONDecoder()
            summaryDecoder.keyDecodingStrategy = .convertFromSnakeCase

            var decodedSummary: ExerciseSessionSummary?

            do {
                decodedSummary = try summaryDecoder.decode(
                    ExerciseSessionSummary.self,
                    from: data
                )
            } catch {
                print("❌ session_summary 디코딩 실패: \(error)")
            }

            let summary = decodedSummary

            DispatchQueue.main.async { [weak self] in

                guard let self = self else {
                    return
                }

                print("======================================")
                print("🏁 SESSION SUMMARY 수신")
                print("🏁 summary: \(String(describing: summary))")
                print("======================================")

                self.finalSummary = summary

                // ExerciseLiveView에서 기다리고 있는 completion 호출
                self.pendingFinishCompletion?(summary)

                self.pendingFinishCompletion = nil

                self.setConnected(false)
                self.isConnecting = false

                self.webSocketTask?.cancel(
                    with: .normalClosure,
                    reason: nil
                )

                self.webSocketTask = nil
            }

            return
        }

        // MARK: Live Analysis

        do {

            let decoded = try JSONDecoder().decode(
                LiveAnalysisMessage.self,
                from: data
            )

            DispatchQueue.main.async { [weak self] in

                guard let self = self else {
                    return
                }

                // 연결 상태 유지
                self.setConnected(true)

                // 상태
                self.status = decoded.status

                // 단계
                self.phaseLabel = decoded.phaseLabel

                // 자세 체크 결과
                self.checkItems = decoded.results ?? []

                // 점수
                if let score = decoded.score {
                    self.currentScore = score
                }

                // MARK: Keypoints

                // 기대 형식: [[x, y]] 또는 [[x, y, conf]], x/y는 0~1 정규화.
                // 서버가 YOLO의 xy(픽셀)를 그대로 보내면 값이 1을 훌쩍 넘으므로
                // 그 경우 마지막으로 보낸 프레임 크기로 나눠 정규화한다.
                if let kp = decoded.keypoints {

                    self.stateLock.lock()
                    let frameSize = self.lastFrameSize
                    self.stateLock.unlock()

                    let maxValue = kp.flatMap { $0.prefix(2) }.max() ?? 0
                    let looksLikePixels = maxValue > 1.5 && frameSize.width > 0

                    if looksLikePixels {
                        print("⚠️ keypoints가 픽셀 좌표로 보임 → 프레임 크기(\(frameSize))로 정규화")
                    }

                    self.keypoints = kp.map { arr in

                        guard arr.count >= 2 else {
                            return .zero
                        }

                        // 신뢰도가 너무 낮은 관절은 숨김(.zero → 오버레이에서 skip)
                        if arr.count >= 3, arr[2] < 0.3 {
                            return .zero
                        }

                        if looksLikePixels {
                            return CGPoint(
                                x: arr[0] / Double(frameSize.width),
                                y: arr[1] / Double(frameSize.height)
                            )
                        }

                        return CGPoint(x: arr[0], y: arr[1])
                    }

                } else {

                    self.keypoints = []
                }

                // MARK: No Person

                if decoded.status == .noPerson {

                    self.keypoints = []

                    self.uncertainMessage =
                        "사람이 보이지 않아요. 카메라 위치를 조정해주세요."

                } else {

                    self.uncertainMessage =
                        decoded.status == .uncertain
                        ? decoded.message
                        : nil
                }

                // MARK: Server Error

                if decoded.status == .error {

                    self.errorMessage = decoded.message

                    print(
                        "❌ Pose Server Error: \(decoded.message ?? "알 수 없는 오류")"
                    )
                }
            }

        } catch {

            print("❌ LiveAnalysisMessage 파싱 실패")
            print("❌ \(error.localizedDescription)")

            DispatchQueue.main.async { [weak self] in

                self?.errorMessage =
                    "서버 응답 파싱 실패: \(error.localizedDescription)"
            }
        }
    }
}
