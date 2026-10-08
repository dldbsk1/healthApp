//
//  ExerciseLiveView.swift
//  TipsyCut
//

import SwiftUI
import AVFoundation

// MARK: - 1. SwiftUI용 실시간 카메라 프리뷰

struct CameraPreviewView: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(
            session: session
        )
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame =
                uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}


// MARK: - 2. ExerciseLiveView

struct ExerciseLiveView: View {
    
    let exerciseName: String
    
    @Binding var path: NavigationPath
    
    @State private var goToEndView = false
    @State private var endViewData: EndViewData?
    @State private var isFinishing = false
    
    let mintColor = Color.mintColor
    
    @StateObject private var poseClient: PoseWebSocketClient
    
    @StateObject private var cameraController =
        CameraCaptureController()
    
    private let backendExerciseName: String?
    
    
    // MARK: - Init
    
    init(
        exerciseName: String,
        path: Binding<NavigationPath>
    ) {
        self.exerciseName = exerciseName
        self._path = path
        
        let backendName =
            ExerciseNameMapping.backendName(
                for: exerciseName
            )
        
        self.backendExerciseName = backendName
        
        _poseClient = StateObject(
            wrappedValue:
                PoseWebSocketClient(
                    exerciseBackendName:
                        backendName ?? exerciseName
                )
        )
    }
    
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            
            // =====================================================
            // 카메라
            // =====================================================
            
            CameraPreviewView(
                session: cameraController.session
            )
            .ignoresSafeArea()
            
            
            // =====================================================
            // AI 스켈레톤
            // =====================================================
            //
            // 서버에서 전달되는 YOLO Pose 17개 관절을
            // SkeletonOverlayView에서 표시
            //
            
            if poseClient.keypoints.count == 17 {
                SkeletonOverlayView(
                    keypoints: poseClient.keypoints
                )
                .ignoresSafeArea()
            }
            
            
            // =====================================================
            // 상단 / 하단 UI
            // =====================================================
            
            VStack {
                
                VStack(spacing: 8) {
                    
                    // -------------------------------------------------
                    // 운동 분석 지원 여부
                    // -------------------------------------------------
                    
                    if backendExerciseName == nil {
                        
                        Text(
                            "이 운동은 아직 자동 분석을 지원하지 않아요."
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Color.black.opacity(0.6)
                        )
                        .cornerRadius(12)
                        
                    }
                    
                    // -------------------------------------------------
                    // 사람 인식 불가
                    // -------------------------------------------------
                    
                    else if let msg =
                        poseClient.uncertainMessage {
                        
                        Text(msg)
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Color.black.opacity(0.6)
                            )
                            .cornerRadius(12)
                    }
                    
                    // -------------------------------------------------
                    // 현재 운동 단계
                    // -------------------------------------------------
                    
                    else if let phase =
                        poseClient.phaseLabel {
                        
                        Text(phase)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Color.black.opacity(0.6)
                            )
                            .cornerRadius(12)
                    }
                    
                    // -------------------------------------------------
                    // 기본 상태
                    // -------------------------------------------------
                    
                    else {
                        
                        Text(
                            "자세를 인식하고 있어요..."
                        )
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Color.black.opacity(0.5)
                        )
                        .cornerRadius(10)
                    }
                    
                    
                    // =================================================
                    // 자세 체크리스트
                    // =================================================
                    
                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {
                        
                        ForEach(
                            poseClient.checkItems
                        ) { item in
                            
                            HStack {
                                
                                Image(
                                    systemName:
                                        item.ok
                                        ? "checkmark.circle.fill"
                                        : "xmark.circle.fill"
                                )
                                .foregroundColor(
                                    item.ok
                                    ? mintColor
                                    : .red
                                )
                                
                                Text(item.desc)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        Color.black.opacity(0.5)
                    )
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                
                // =====================================================
                // 에러
                // =====================================================
                
                if let error =
                    poseClient.errorMessage {
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(6)
                        .background(
                            Color.black.opacity(0.7)
                        )
                        .cornerRadius(8)
                }
                
                
                Spacer()
                
                
                // =====================================================
                // 운동 완료 버튼
                // =====================================================
                
                Button(
                    action: finishExercise
                ) {
                    
                    Text(
                        isFinishing
                        ? "운동을 정리하고 있어요..."
                        : "운동 완료"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isFinishing
                        ? Color.gray
                        : mintColor
                    )
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                .disabled(isFinishing)
                .padding(.bottom, 20)
            }
        }
        
        
        // =========================================================
        // 화면 진입
        // =========================================================
        
        .onAppear {
            
            guard backendExerciseName != nil else {
                return
            }
            
            cameraController.poseClient =
                poseClient
            
            poseClient.connect()
            cameraController.start()
        }
        
        
        // =========================================================
        // 화면 이탈
        // =========================================================
        
        .onDisappear {
            
            cameraController.stop()
            
            if poseClient.isConnected {
                poseClient.disconnect()
            }
        }
        
        
        // =========================================================
        // EndView 이동
        // =========================================================
        
        .navigationDestination(
            isPresented: $goToEndView
        ) {
            
            if let data = endViewData {
                
                ExerciseEndView(
                    path: $path,
                    exercise: data.exercise,
                    totalTime: data.totalTime,
                    totalCalories: data.totalCalories,
                    accuracy: data.accuracy,
                    setCount: data.setCount,
                    repsPerSet: data.repsPerSet,
                    resultData: data.resultData,
                    isHold: data.isHold
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - 운동 완료
    
    private func finishExercise() {
        
        guard !isFinishing else {
            return
        }
        
        isFinishing = true
        
        
        // =========================================================
        // 카메라 먼저 정지
        // =========================================================
        
        cameraController.stop()
        
        
        // =========================================================
        // 자동 분석 미지원 운동
        // =========================================================
        
        guard backendExerciseName != nil else {
            
            DispatchQueue.main.async {
                
                let placeholder =
                    EndViewData.placeholder(
                        exerciseName: exerciseName
                    )
                
                // 분석 데이터가 없는 placeholder는 누적 기록에 넣지 않는다
                
                endViewData = placeholder
                goToEndView = true
                isFinishing = false
            }
            
            return
        }
        
        
        // =========================================================
        // WebSocket 세션 종료
        // =========================================================
        
        poseClient.finishSession { summary in
            
            DispatchQueue.main.async {
                
                // -------------------------------------------------
                // summary를 못 받았을 경우
                // -------------------------------------------------
                
                guard let summary = summary else {
                    
                    print("⚠️ session_summary를 받지 못했습니다. 결과가 비어 있습니다.")
                    
                    let placeholder =
                        EndViewData.placeholder(
                            exerciseName: exerciseName
                        )
                    
                    endViewData = placeholder
                    goToEndView = true
                    isFinishing = false
                    
                    return
                }
                
                
                // =================================================
                // 서버 summary를 받은 즉시
                // ExerciseResultData 생성 및 Store 저장
                // =================================================
                
                // 플랭크 등 유지형 운동인지 (서버 hold_seconds가 비어 있어도 이름으로 판단)
                let hold =
                    summary.isHold
                    || ExerciseKind.isHold(exerciseName)
                
                let holdSec =
                    Int(summary.holdDisplaySeconds)
                
                let result =
                    summary.toResultData(
                        serverCalories: nil,
                        displayName: exerciseName,
                        isHold: hold
                    )
                
                // 누적 기록에 추가 (런지 → 레그레이즈 순서로 하면 둘 다 쌓임)
                ExerciseResultStore.shared.add(
                    result
                )
                
                
                // =================================================
                // EndView 표시
                //
                // Spring Boot 저장은 별도로 진행
                // =================================================
                
                endViewData =
                    EndViewData(
                        exercise:
                            matchedExercise(),
                        
                        totalTime:
                            formatDuration(
                                summary.totalSeconds
                            ),
                        
                        totalCalories:
                            Int(
                                result.totalCalories
                            ),
                        
                        accuracy:
                            Int(
                                summary.avgScore
                            ),
                        
                        setCount:
                            1,
                        
                        repsPerSet:
                            hold
                            ? holdSec
                            : (summary.repCount ?? 0),
                        
                        resultData:
                            result,
                        
                        isHold:
                            hold
                    )
                
                goToEndView = true
                isFinishing = false
                
                
                // =================================================
                // Spring Boot 저장
                // =================================================
                
                saveExerciseLog(
                    summary: summary
                ) { logResponse in
                    
                    guard
                        let calories =
                            logResponse?.caloriesBurned
                    else {
                        return
                    }
                    
                    // Spring Boot가 계산한 caloriesBurned로
                    // 이 세션의 칼로리를 확정 (EndView / AnalysisView 모두 반영)
                    
                    ExerciseResultStore.shared.updateCalories(
                        sessionID: result.id,
                        calories: calories
                    )
                }
            }
        }
    }
    
    
    // MARK: - Exercise 매칭
    
    private func matchedExercise() -> Exercise {
        
        Exercise.recommendedList.first {
            $0.name == exerciseName
        }
        ?? Exercise.recommendedList[0]
    }
    
    
    // MARK: - 시간 포맷
    
    private func formatDuration(
        _ seconds: Double
    ) -> String {
        
        let total = Int(seconds)
        
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        
        return String(
            format: "%02d:%02d:%02d",
            h,
            m,
            s
        )
    }
    
    
    // MARK: - Spring Boot API 저장
    
    private func saveExerciseLog(
        summary: ExerciseSessionSummary,
        completion:
            @escaping (ExerciseLogResponse?) -> Void
    ) {
        
        guard let url =
            URL(
                string:
                    "\(AppConfig.springBootBaseURL)/api/exercises/logs?userId=\(AppConfig.temporaryUserId)"
            )
        else {
            
            DispatchQueue.main.async {
                completion(nil)
            }
            
            return
        }
        
        
        let request =
            ExerciseLogCreateRequest(
                exerciseName:
                    summary.exercise
                    ?? exerciseName,
                
                // 서버가 분 단위로 칼로리를 계산하므로 최소 1분
                durationMin:
                    max(summary.durationMin, 1),
                
                sets:
                    1,
                
                // 플랭크는 횟수가 아니라 시간 기반이라 reps를 보내지 않는다
                reps:
                    summary.isHold
                    || ExerciseKind.isHold(exerciseName)
                    ? nil
                    : summary.repCount,
                
                score:
                    Double(summary.avgScore),
                
                exercisedAt:
                    ISO8601DateFormatter()
                        .string(from: Date())
            )
        
        
        var urlRequest =
            URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )
        
        urlRequest.httpBody =
            try? JSONEncoder()
                .encode(request)
        
        
        URLSession.shared.dataTask(
            with: urlRequest
        ) { data, response, error in
            
            // -----------------------------------------------------
            // 네트워크 오류
            // -----------------------------------------------------
            
            if let error = error {
                
                print(
                    "운동 기록 저장 실패: \(error.localizedDescription)"
                )
                
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }
            
            
            // -----------------------------------------------------
            // 데이터 없음
            // -----------------------------------------------------
            
            guard let data = data else {
                
                print(
                    "운동 기록 저장 실패: 응답 데이터 없음"
                )
                
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }
            
            
            // -----------------------------------------------------
            // 응답 디코딩
            // -----------------------------------------------------
            
            let statusCode =
                (response as? HTTPURLResponse)?.statusCode ?? -1
            
            print(
                "운동 기록 저장 응답 [\(statusCode)]: \(String(data: data, encoding: .utf8) ?? "-")"
            )
            
            do {
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decoded =
                    try decoder
                        .decode(
                            ApiResponse<ExerciseLogResponse>.self,
                            from: data
                        )
                
                DispatchQueue.main.async {
                    completion(decoded.data)
                }
                
            } catch {
                
                print(
                    "운동 기록 응답 디코딩 실패: \(error)"
                )
                print(
                    "운동 기록 원본 응답: \(String(data: data, encoding: .utf8) ?? "-")"
                )
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        .resume()
    }
}


// MARK: - EndViewData

private struct EndViewData {
    
    let exercise: Exercise
    let totalTime: String
    let totalCalories: Int
    let accuracy: Int
    let setCount: Int
    let repsPerSet: Int
    let resultData: ExerciseResultData
    let isHold: Bool
    
    
    static func placeholder(
        exerciseName: String
    ) -> EndViewData {
        
        let result =
            ExerciseResultData(
                exerciseName:
                    exerciseName,
                
                totalTime:
                    "00:00:00",
                
                totalCalories:
                    0,
                
                averageAccuracy:
                    0,
                
                setCount:
                    1,
                
                repsPerSet:
                    0
            )
        
        return EndViewData(
            exercise:
                Exercise.recommendedList.first {
                    $0.name == exerciseName
                }
                ?? Exercise.recommendedList[0],
            
            totalTime:
                "00:00:00",
            
            totalCalories:
                0,
            
            accuracy:
                0,
            
            setCount:
                1,
            
            repsPerSet:
                0,
            
            resultData:
                result,
            
            isHold:
                ExerciseKind.isHold(exerciseName)
        )
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        ExerciseLiveView(
            exerciseName: "니푸쉬업",
            path:
                .constant(
                    NavigationPath()
                )
        )
    }
}
