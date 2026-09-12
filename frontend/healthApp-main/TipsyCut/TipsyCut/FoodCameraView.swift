import SwiftUI
import ARKit
import SceneKit
import simd

struct FoodCameraView: View {
    @Binding var showCamera: Bool
    
    // 💡 [추가] 저장 완료 시 부모(FoodMainView)가 식단 목록을 갱신하도록 알리는 콜백
    var onSaveComplete: () -> Void = {}
    
    @State private var path = NavigationPath()
    
    @StateObject private var arManager = ARManager()
    @State private var isLoading = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ARViewContainer(arManager: arManager)
                    .ignoresSafeArea()
                
                // 중앙 타겟팅 UI
                Circle()
                    .stroke(targetRingColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(targetStatusText)
                            .font(.caption)
                            .foregroundColor(.white)
                            .offset(y: -30)
                            .fixedSize()
                    )
                
                VStack {
                    // 💡 [추가] 수평 기울기 경고 배너 — 렌즈 왜곡으로 면적 계산이 부정확해지는 걸 방지
                    if arManager.isTargetDetected && !arManager.isLevelEnough {
                        HStack(spacing: 6) {
                            Image(systemName: "level")
                            Text("폰을 수평으로 맞춰주세요 (기울기 \(Int(arManager.tiltAngleDegrees))°)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(20)
                        .padding(.top, 12)
                    }
                    
                    if let thickness = arManager.estimatedThickness {
                        Text(String(format: "실측 두께: %.1f cm", thickness))
                            .font(.title2)
                            .bold()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        captureAndAnalyze()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 75, height: 75)
                            .overlay(
                                Circle()
                                    .stroke(canCapture ? Color.green : Color.gray, lineWidth: 5)
                            )
                            .shadow(radius: 5)
                            .opacity(canCapture ? 1.0 : 0.5)
                    }
                    .disabled(isLoading || !canCapture)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("AR 식단 측정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { showCamera = false }
                        .foregroundColor(.white)
                }
            }
            .navigationDestination(for: AIArticleResult.self) { result in
                FoodSaveView(
                    showCamera: $showCamera,
                    path: $path,
                    foodName: result.foodName,
                    foodWeight: String(Int(result.weightG)),
                    calories: result.caloriesKcal,
                    needsSpoonMessage: result.message, // 💡 [추가] 숟가락 미인식 시 안내 문구 전달
                    onSaveComplete: onSaveComplete     // 💡 [추가] 저장 완료 알림 전달
                )
            }
            .overlay {
                if isLoading {
                    ProgressView("AI 정밀 분석 중...")
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }

    // 💡 [추가] 타겟 인식 + 수평 기울기 조건을 모두 만족해야 촬영 가능
    private var canCapture: Bool {
        arManager.isTargetDetected && arManager.isLevelEnough
    }
    
    private var targetRingColor: Color {
        if !arManager.isTargetDetected { return .white }
        return arManager.isLevelEnough ? .green : .orange
    }
    
    private var targetStatusText: String {
        if !arManager.isTargetDetected { return "음식을 중앙에 맞추세요" }
        return arManager.isLevelEnough ? "🎯 측정 가능" : "📐 기울기를 조절하세요"
    }

    private func captureAndAnalyze() {
        guard canCapture else { return }
        
        // 💡 수정됨: 측정 실패(nil) 시 서버에 0.0을 전송하여 백엔드의 FOOD_PRIORS 기반 재보정을 유도함
        // (바나나 등 형태가 뚜렷한 식재료는 AR 실측 두께 대신 크기 카테고리별 표준 두께를 백엔드에서 적용할 예정)
        let finalThickness = arManager.estimatedThickness ?? 0.0
        
        // AI 분석용 고해상도 원본 이미지 추출
        guard let highResImage = arManager.getHighResolutionImage() else {
            print("❌ 고해상도 이미지 캡처 실패")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Java Spring Boot(8080) -> Python FastAPI 프록시 통신
                let response = try await NetworkManager.shared.uploadImageWithARData(image: highResImage, thickness: finalThickness)
                isLoading = false
                
                if let topResult = response.results.first {
                    path.append(topResult)
                } else {
                    print("⚠️ 서버 분석 결과에 음식 데이터가 비어있습니다.")
                }
            } catch {
                print("❌ 서버 연동 실패: \(error)")
                isLoading = false
            }
        }
    }
}

class ARManager: NSObject, ObservableObject, ARSCNViewDelegate {
    @Published var isTargetDetected = false
    @Published var estimatedThickness: Double? = nil
    
    // 💡 [추가] 수평(탑다운) 기울기 상태
    @Published var isLevelEnough = true
    @Published var tiltAngleDegrees: Double = 0.0
    
    // 탑다운 촬영 기준 허용 최대 기울기(도). 작을수록 렌즈 왜곡/면적 오차는 줄지만
    // 사용자가 맞추기 어려워짐 -> 실사용 기준 5~7도가 절충점
    private let maxTiltDegrees: Double = 6.0
    
    var sceneView: ARSCNView?
    private var tableY: Float?
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let sceneView = sceneView else { return }
        
        // 💡 [추가] 매 프레임 기울기 계산
        // 카메라는 로컬 -Z 방향을 바라보므로, transform의 column2(로컬 Z축)를 뒤집으면
        // 월드 좌표계에서 카메라가 바라보는 실제 방향(forward)이 됨.
        // ARKit 기본 worldAlignment(.gravity)에서는 월드 Y축이 중력 반대(위쪽)이므로,
        // forward가 "아래(0,-1,0)"와 이루는 각도가 0에 가까울수록 완전한 탑다운 촬영임.
        // 오일러 각(pitch/roll) 대신 벡터 내적을 쓰는 이유는 짐벌락 구간에서도 안정적이기 때문.
        if let camera = sceneView.session.currentFrame?.camera {
            let col2 = camera.transform.columns.2
            let forward = simd_normalize(SIMD3<Float>(-col2.x, -col2.y, -col2.z))
            let down = SIMD3<Float>(0, -1, 0)
            let dot = max(-1.0, min(1.0, simd_dot(forward, down)))
            let tiltDeg = Double(acos(dot) * 180.0 / Float.pi)
            
            DispatchQueue.main.async {
                self.tiltAngleDegrees = tiltDeg
                self.isLevelEnough = tiltDeg <= self.maxTiltDegrees
            }
        }
        
        let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        
        // 1. 음식 표면 (가장 먼저 타격되는 표면)
        let foodQuery = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
        
        // 2. 식탁 평면 (확실히 인식된 수평 평면)
        let tableQuery = sceneView.raycastQuery(from: screenCenter, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        guard let fQuery = foodQuery,
              let foodHit = sceneView.session.raycast(fQuery).first else {
            DispatchQueue.main.async { self.isTargetDetected = false }
            return
        }
        
        let foodPos = foodHit.worldTransform.columns.3
        
        // 식탁 평면이 감지되면 tableY 갱신 (화면 중앙 기준)
        if let tQuery = tableQuery, let tableHit = sceneView.session.raycast(tQuery).first {
            self.tableY = tableHit.worldTransform.columns.3.y
        }
        
        DispatchQueue.main.async {
            self.isTargetDetected = true
            let hitY = foodPos.y
            
            if let tableY = self.tableY {
                let thickness = (hitY - tableY) * 100.0 // cm 변환
                
                // 💡 수정됨: 합리적 범위 (0.5cm ~ 15.0cm) 안이면 실측값 사용
                if thickness >= 0.5 && thickness <= 15.0 {
                    self.estimatedThickness = Double(thickness)
                } else {
                    // 비정상 -> 측정 실패 처리 (서버가 음식별 두께로 재보정하도록 유도)
                    self.estimatedThickness = nil
                }
            } else {
                // 식탁 아직 미인식 -> 측정 불가 표시
                self.estimatedThickness = nil
            }
        }
    }
    
    // AI 모델 정확도를 위한 원본 픽셀 버퍼 -> UIImage 변환 유틸리티
    func getHighResolutionImage() -> UIImage? {
        guard let pixelBuffer = sceneView?.session.currentFrame?.capturedImage else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        // ARKit 카메라는 기본이 가로(Landscape Right) 방향이므로 .right로 회전 보정
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arManager: ARManager
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = arManager
        arManager.sceneView = sceneView
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic // 표면 인식률 향상
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration)
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
