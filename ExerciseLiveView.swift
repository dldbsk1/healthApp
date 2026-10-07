//
//
//  ExerciseLiveView.swift
//  TipsyCut
//

import SwiftUI
import AVFoundation

// MARK: - 1. SwiftUI용 실시간 카메라 프리뷰 레이어
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - 2. ExerciseLiveView 메인 뷰
struct ExerciseLiveView: View {

    let exerciseName: String
    @Binding var path: NavigationPath

    @State private var goToEndView = false
    @State private var endViewData: EndViewData?

    // Models에 선언된 공통 메인 색상 식별자
    let mintColor = Color.mintColor

    @StateObject private var poseClient: PoseWebSocketClient
    @StateObject private var cameraController = CameraCaptureController()

    private let backendExerciseName: String?

    init(exerciseName: String, path: Binding<NavigationPath>) {
        self.exerciseName = exerciseName
        self._path = path

        let backendName = ExerciseNameMapping.backendName(for: exerciseName)
        self.backendExerciseName = backendName

        _poseClient = StateObject(wrappedValue: PoseWebSocketClient(exerciseBackendName: backendName ?? exerciseName))
    }

    var body: some View {
        ZStack {
            // 📸 실시간 전면 카메라 화면 전체 채우기
            CameraPreviewView(session: cameraController.session)
                .ignoresSafeArea()

            // 🎨 카메라 위 오버레이 (상태 및 체크리스트)
            VStack {
                VStack(spacing: 8) {
                    if backendExerciseName == nil {
                        Text("이 운동은 아직 자동 분석을 지원하지 않아요.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    } else if let msg = poseClient.uncertainMessage {
                        Text(msg)
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    } else if let phase = poseClient.phaseLabel {
                        Text(phase)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    } else {
                        Text("자세를 인식하고 있어요...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }

                    // 자세 가이드 체크리스트
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(poseClient.checkItems) { item in
                            HStack {
                                Image(systemName: item.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(item.ok ? mintColor : .red)
                                Text(item.desc)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                .padding(.top, 20)

                if let error = poseClient.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }

                Spacer()

                // 운동 완료 버튼
                Button(action: finishExercise) {
                    Text("운동 완료")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(mintColor)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            guard backendExerciseName != nil else { return }
            cameraController.poseClient = poseClient
            poseClient.connect()
            cameraController.start()
        }
        .onDisappear {
            cameraController.stop()
            if poseClient.isConnected {
                poseClient.disconnect()
            }
        }
        .navigationDestination(isPresented: $goToEndView) {
            if let data = endViewData {
                ExerciseEndView(
                    path: $path,
                    exercise: data.exercise,
                    totalTime: data.totalTime,
                    totalCalories: data.totalCalories,
                    accuracy: data.accuracy,
                    setCount: data.setCount,
                    repsPerSet: data.repsPerSet
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 운동 완료 처리 (WebSocket 세션 종료 + REST API 저장)

    private func finishExercise() {
        cameraController.stop()

        guard backendExerciseName != nil else {
            endViewData = EndViewData.placeholder(exerciseName: exerciseName)
            goToEndView = true
            return
        }

        poseClient.finishSession { summary in
            guard let summary = summary else {
                endViewData = EndViewData.placeholder(exerciseName: exerciseName)
                goToEndView = true
                return
            }

            saveExerciseLog(summary: summary) { logResponse in
                endViewData = EndViewData(
                    exercise: matchedExercise(),
                    totalTime: formatDuration(summary.durationSec),
                    totalCalories: logResponse?.caloriesBurned ?? 0,
                    accuracy: summary.avgScore,
                    setCount: 1,
                    repsPerSet: summary.repCount ?? Int(summary.holdSeconds ?? 0)
                )
                goToEndView = true
            }
        }
    }

    private func matchedExercise() -> Exercise {
        Exercise.recommendedList.first(where: { $0.name == exerciseName }) ?? Exercise.recommendedList[0]
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Spring Boot API 데이터 저장 (POST /api/exercises/logs)

    private func saveExerciseLog(summary: ExerciseSessionSummary, completion: @escaping (ExerciseLogResponse?) -> Void) {
        guard let url = URL(string: "\(AppConfig.springBootBaseURL)/api/exercises/logs?userId=\(AppConfig.temporaryUserId)") else {
            completion(nil)
            return
        }

        let request = ExerciseLogCreateRequest(
            exerciseName: summary.exercise ?? exerciseName,
            durationMin: summary.durationMin,
            reps: summary.repCount,
            score: Double(summary.avgScore),
            exercisedAt: ISO8601DateFormatter().string(from: Date())
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)

        URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if let error = error {
                print("운동 기록 저장 실패: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ApiResponse<ExerciseLogResponse>.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(decoded.data) }
        }.resume()
    }
}

// MARK: - 3. EndViewData 모델
private struct EndViewData {
    let exercise: Exercise
    let totalTime: String
    let totalCalories: Int
    let accuracy: Int
    let setCount: Int
    let repsPerSet: Int

    static func placeholder(exerciseName: String) -> EndViewData {
        EndViewData(
            exercise: Exercise.recommendedList.first(where: { $0.name == exerciseName }) ?? Exercise.recommendedList[0],
            totalTime: "00:00:00",
            totalCalories: 0,
            accuracy: 0,
            setCount: 1,
            repsPerSet: 0
        )
    }
}

#Preview {
    NavigationStack {
        ExerciseLiveView(
            exerciseName: "니푸쉬업",
            path: .constant(NavigationPath())
        )
    }
}
