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
    @Environment(\.dismiss) private var dismiss
    
    @State private var endViewData: EndViewData?
    @State private var isFinishing = false
    @State private var countPop = false   // 횟수가 올라갈 때 숫자가 톡 튀는 효과용
    
    // 플랭크: 자세 미인식 감지 → 종료 확인 알림
    @State private var hasRecognized = false      // 한 번이라도 자세가 인식됐는지
    @State private var lostSince: Date? = nil     // 자세가 인식되지 않기 시작한 시각
    @State private var showEndPrompt = false      // "운동을 종료하시겠습니까?" 알림
    @State private var promptSnoozed = false      // "계속하기"를 누른 뒤 다시 인식되기 전까지 알림 금지
    
    // 플랭크: 체크 두 개가 모두 민트 ✓일 때만 흐르는 시간(초)
    @State private var plankHoldSeconds: Double = 0
    @State private var lastHoldTick: Date? = nil
    
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
                        
                        ForEach(visibleRows) { row in
                            
                            let ok = displayState(row)
                            
                            HStack {
                                
                                Image(
                                    systemName:
                                        ok
                                        ? "checkmark.circle.fill"
                                        : "xmark.circle.fill"
                                )
                                .font(.system(size: 45))
                                .foregroundColor(
                                    ok ? mintColor : .red
                                )
                                
                                // 문구는 항상 고정, 체크 아이콘만 현재 평가로 바뀜
                                Text(row.title)
                                    .font(.system(size: 45, weight: .medium))
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
                    .animation(
                        .easeInOut(duration: 0.15),
                        value: poseClient.move
                    )
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
            
            
            // =====================================================
            // 화면 정중앙 카운터
            // 반복 운동: 횟수 / 플랭크: 정상 자세 유지 시간(mm:ss)
            // 터치는 아래 화면으로 통과
            // =====================================================
            
            if backendExerciseName != nil {
                counterBadge
                    .offset(y: 30)
                    .allowsHitTesting(false)
            }
        }
        
        
        // =========================================================
        // 뒤로가기: 바로 이전 화면(ExerciseContentView / 운동 목록)으로
        // =========================================================
        
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if !path.isEmpty {
                        path.removeLast()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
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
        // 횟수가 올라갈 때 진동 + 숫자 애니메이션
        // =========================================================
        
        .onChange(of: poseClient.repCount) { newCount in
            
            guard newCount > 0 else {
                return
            }
            
            UIImpactFeedbackGenerator(style: .medium)
                .impactOccurred()
            
            withAnimation(
                .spring(response: 0.25, dampingFraction: 0.5)
            ) {
                countPop = true
            }
            
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.2
            ) {
                withAnimation(.easeOut(duration: 0.15)) {
                    countPop = false
                }
            }
        }
        
        
        // =========================================================
        // 플랭크: 5초 이상 자세 미인식 → 종료 확인
        // =========================================================
        
        .onReceive(recognitionTimer) { _ in
            checkRecognition()
        }
        .onReceive(holdTickTimer) { _ in
            tickHold()
        }
        .onReceive(poseClient.$checkItems) { items in
            updateLastStates(items)
        }
        .alert(
            "운동을 종료하시겠습니까?",
            isPresented: $showEndPrompt
        ) {
            
            Button("운동 종료", role: .destructive) {
                finishExercise()
            }
            
            Button("계속하기", role: .cancel) {
                // 다시 인식될 때까지 알림 안 띄움
                promptSnoozed = true
            }
            
        } message: {
            Text("자세가 5초 이상 인식되지 않았어요.")
        }
        
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - 실시간 카운터
    
    /// 플랭크처럼 횟수가 아니라 시간으로 재는 운동인지
    private var isHoldExercise: Bool {
        ExerciseKind.isHold(exerciseName)
    }
    
    /// 서버가 사람/자세를 인식한 상태인지 (no_person, uncertain, error는 미인식)
    private var isRecognized: Bool {
        poseClient.status == .collecting
        || poseClient.status == .analyzing
    }
    
    /// 0.5초마다 미인식 시간을 확인하는 타이머
    private let recognitionTimer =
        Timer.publish(
            every: 0.5,
            on: .main,
            in: .common
        )
        .autoconnect()
    
    /// 0.1초마다 플랭크 시간을 갱신하는 타이머
    private let holdTickTimer =
        Timer.publish(
            every: 0.1,
            on: .main,
            in: .common
        )
        .autoconnect()
    
    /// 플랭크: 화면에 보이는 체크 아이콘이 전부 민트 ✓이고 자세가 인식 중일 때만 시간을 올린다.
    private func tickHold() {
        
        let now = Date()
        defer { lastHoldTick = now }
        
        guard isHoldExercise,
              backendExerciseName != nil,
              !isFinishing,
              isRecognized,
              !fixedRows.isEmpty,
              fixedRows.allSatisfy({ displayState($0) }),
              let last = lastHoldTick else {
            return
        }
        
        // 화면이 잠깐 멈췄을 때 시간이 한꺼번에 뛰지 않도록 상한
        plankHoldSeconds += min(now.timeIntervalSince(last), 0.5)
    }
    
    /// 초 → "mm:ss"
    private func formatHold(
        _ seconds: Double
    ) -> String {
        
        let total = Int(seconds)
        
        return String(
            format: "%02d:%02d",
            total / 60,
            total % 60
        )
    }
    
    /// 플랭크에서 5초 이상 자세가 인식되지 않았는지 확인
    private func checkRecognition() {
        
        guard isHoldExercise,
              backendExerciseName != nil,
              !isFinishing else {
            return
        }
        
        if isRecognized {
            hasRecognized = true
            lostSince = nil
            promptSnoozed = false
            showEndPrompt = false      // 다시 인식되면 알림 자동으로 닫기
            return
        }
        
        // 한 번도 인식되기 전(연결 중)에는 알림을 띄우지 않음
        guard hasRecognized else {
            return
        }
        
        if lostSince == nil {
            lostSince = Date()
        } else if let start = lostSince,
                  Date().timeIntervalSince(start) >= 5,
                  !showEndPrompt,
                  !promptSnoozed {
            showEndPrompt = true
        }
    }
    
    // MARK: - 체크리스트 고정 문구
    
    /// 화면에 고정으로 보여줄 한 줄.
    /// title : 화면에 항상 표시되는 짧은 문구
    /// keys  : 서버 항목을 찾는 키워드 (label 우선, 없으면 desc에서 찾음).
    ///         하나라도 틀리면 ✗, 전부 맞으면 ✓
    private struct FixedRow: Identifiable {
        let title: String
        let keys: [String]
        /// false면 서버 평가를 반영하지 않고 항상 ✓로 고정
        var evaluated: Bool = true
        /// "up"/"down"이면 그 동작을 하는 중에만 화면에 보인다. nil이면 항상 보인다.
        var move: String? = nil
        var id: String { title }
    }
    
    /// 운동별 고정 문구. (키: 화면에 표시되는 운동 이름)
    private static let fixedRowTable: [String: [FixedRow]] = [
        "니푸쉬업": [
            FixedRow(title: "팔꿈치 굽히기",    keys: ["굽힘 깊이"], move: "down"),
            FixedRow(title: "팔 끝까지 펴기",   keys: ["펴짐"],     move: "up"),
            FixedRow(title: "허리 펴기",   keys: ["허리"])
        ],
        "런지": [
            FixedRow(title: "앞무릎 각도",   keys: ["앞무릎"]),
            FixedRow(title: "뒷무릎 굽히기", keys: ["뒷무릎"]),
            FixedRow(title: "상체 펴기",     keys: ["상체"]),
        ],
        "레그레이즈": [
            FixedRow(title: "더 내려가세요", keys: ["내린 높이"],     move: "down"),
            FixedRow(title: "더 올라가세요", keys: ["들어올린 높이"], move: "up")
        ],
        "플랭크": [
            FixedRow(title: "엉덩이 일직선", keys: ["엉덩이"]),
            FixedRow(title: "다리 펴기",     keys: ["다리 일직선"]),
            FixedRow(title: "팔 각도 직각",   keys: ["팔 각도", "팔"]),
        ],
    ]
    
    private var fixedRows: [FixedRow] {
        Self.fixedRowTable[exerciseName] ?? []
    }
    
    /// 화면에 그릴 줄. 지금 하는 동작(올리는 중/내리는 중)에 해당하는 줄만 보여준다.
    /// 동작을 아직 모르면(자세 잡기 전 등) 전부 보여준다. (판정 로직은 fixedRows 전체를 그대로 사용)
    private var visibleRows: [FixedRow] {
        
        // 레그레이즈: "더 내려가세요 / 더 올라가세요"는 항상 한 줄만 보여준다.
        // 동작을 아직 모르면 첫 번째 줄(내리기)을 기본으로 보여준다.
        if exerciseName == "레그레이즈" {
            
            let current = poseClient.move ?? "down"
            
            return fixedRows.filter {
                $0.move == nil || $0.move == current
            }
        }
        
        guard let move = poseClient.move else {
            return fixedRows
        }
        
        return fixedRows.filter {
            $0.move == nil || $0.move == move
        }
    }
    
    /// 서버가 마지막으로 알려준 줄별 평가 (판정이 잠깐 끊겨도 아이콘이 비지 않게 유지)
    /// 첫 판정 전에는 ✗로 시작한다.
    @State private var lastStates: [String: Bool] = [:]
    
    /// 지금 서버 항목에서 이 줄의 평가: true=정상, false=교정 필요, nil=이번 프레임엔 판정 없음
    /// 평가(오케이) 값은 서버가 실시간으로 보내는 값을 그대로 사용한다.
    private func rowState(
        _ row: FixedRow,
        in items: [PoseCheckItem]
    ) -> Bool? {
        
        // 1순위: label에 키워드가 있는 항목
        for key in row.keys {
            let matched = items.filter { $0.label.contains(key) }
            if !matched.isEmpty {
                return matched.allSatisfy { $0.ok }
            }
        }
        
        // 2순위: label에 없으면 desc에서 찾기
        for key in row.keys {
            let matched = items.filter { $0.desc.contains(key) }
            if !matched.isEmpty {
                return matched.allSatisfy { $0.ok }
            }
        }
        
        return nil
    }
    
    /// 화면에 그릴 아이콘 상태 (항상 true/false 중 하나 → 체크박스가 비지 않음)
    private func displayState(_ row: FixedRow) -> Bool {
        
        guard row.evaluated else {
            return true
        }
        
        return rowState(row, in: poseClient.checkItems)
            ?? lastStates[row.title]
            ?? false
    }
    
    /// 서버 항목이 갱신될 때마다 줄별 마지막 평가를 저장
    private func updateLastStates(_ items: [PoseCheckItem]) {
        
        for row in fixedRows where row.evaluated {
            if let state = rowState(row, in: items) {
                lastStates[row.title] = state
            }
        }
    }
    
    
    private var counterBadge: some View {
        
        Group {
            
            if isHoldExercise {
                
                // 플랭크: 정상 자세로 버틴 시간 (mm:ss)
                // 자세가 흐트러지면 서버 값이 늘지 않아 시간이 멈춤
                VStack(spacing: 6) {
                    
                    Text(formatHold(plankHoldSeconds))
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if !isRecognized {
                        Text("자세를 인식하고 있어요")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .opacity(0.9)
                    }
                }
                
            } else {
                
                // 반복 운동: 횟수
                Text("\(poseClient.repCount)")
                    .font(.system(size: 160, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .scaleEffect(countPop ? 1.25 : 1.0)
            }
        }
        .foregroundColor(.white)
        // 카메라 화면 위에서 잘 보이게
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 2)
    }
    
    
    // MARK: - 운동 완료
    
    private func finishExercise() {
        
        guard !isFinishing else {
            return
        }
        
        isFinishing = true
        
        // 플랭크: 지금 화면에 흐르던 시간(정상 자세 유지 시간)을 결과 시간으로 사용
        let shownHold: Double? =
            isHoldExercise ? plankHoldSeconds : nil
        
        
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
                if let data = endViewData { path.append(data) }
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
                    if let data = endViewData { path.append(data) }
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
                    Int(shownHold ?? summary.holdDisplaySeconds)
                
                // 운동을 실제로 안 했는지 (반복 운동: 0회 / 플랭크: 정상 자세 유지 0초)
                // → 칼로리 0, 서버 저장도 하지 않는다
                let didNothing =
                    hold
                    ? holdSec == 0
                    : (summary.repCount ?? 0) == 0
                
                let result =
                    summary.toResultData(
                        serverCalories: didNothing ? 0 : nil,
                        displayName: exerciseName,
                        isHold: hold,
                        holdSecondsOverride: shownHold
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
                                shownHold ?? summary.totalSeconds
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
                
                if let data = endViewData { path.append(data) }
                isFinishing = false
                
                
                // =================================================
                // Spring Boot 저장
                // =================================================
                
                guard !didNothing else {
                    return
                }
                
                saveExerciseLog(
                    summary: summary,
                    activeSeconds: hold ? Double(holdSec) : nil
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
        activeSeconds: Double? = nil,
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
        
        
        // 플랭크는 카메라 켜진 시간이 아니라 정상 자세로 버틴 시간, 그 외는 총 운동 시간
        let effectiveSec =
            max(activeSeconds ?? summary.totalSeconds, 0)
        
        let request =
            ExerciseLogCreateRequest(
                exerciseName:
                    summary.exercise
                    ?? exerciseName,
                
                // 기록 표시용 분 단위(최소 1분). 칼로리는 아래 durationSec(초)로 계산된다.
                durationMin:
                    max(Int((effectiveSec / 60).rounded()), 1),
                
                // 칼로리 계산용 정확한 시간(초)
                durationSec:
                    Int(effectiveSec.rounded()),
                
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
            
            // ——————————————————————————
            // 네트워크 오류
            // ——————————————————————————
            
            if let error = error {
                
                print(
                    "운동 기록 저장 실패: \(error.localizedDescription)"
                )
                
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }
            
            
            // ——————————————————————————
            // 데이터 없음
            // ——————————————————————————
            
            guard let data = data else {
                
                print(
                    "운동 기록 저장 실패: 응답 데이터 없음"
                )
                
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }
            
            
            // ——————————————————————————
            // 응답 디코딩
            // ——————————————————————————
            
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

struct EndViewData: Hashable {
    
    // NavigationPath에 넣기 위한 식별자 (id가 같으면 같은 화면으로 취급)
    let id = UUID()
    
    static func == (lhs: EndViewData, rhs: EndViewData) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
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
