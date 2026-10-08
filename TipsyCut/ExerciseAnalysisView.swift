//
//  ExerciseAnalysisView.swift
//  TipsyCut
//

import SwiftUI

// MARK: - Exercise Category Enum

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case strength = "웨이트"
    case cardio = "유산소"

    var id: String {
        self.rawValue
    }
}

// MARK: - Data Models

struct SetAnalysis: Identifiable {
    let id = UUID()

    var exerciseName: String
    var category: ExerciseCategory
    var setNumber: Int
    var weight: Double?
    var completed: Int?
    var total: Int?
    var durationString: String?
    var distanceKm: Double?

    var totalSeconds: Int? {
        guard let str = durationString?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !str.isEmpty else {
            return nil
        }

        let components = str
            .split(separator: ":")
            .compactMap { Int($0) }

        if components.count == 3 {
            return components[0] * 3600
                + components[1] * 60
                + components[2]
        } else if components.count == 2 {
            return components[0] * 60
                + components[1]
        } else if components.count == 1 {
            return components[0] * 60
        }

        return nil
    }

    var calculatedPace: String? {
        guard let seconds = totalSeconds,
              seconds > 0,
              let dist = distanceKm,
              dist > 0 else {
            return nil
        }

        let paceInSecondsPerKm = Int(Double(seconds) / dist)
        let paceMinutes = paceInSecondsPerKm / 60
        let paceSeconds = paceInSecondsPerKm % 60

        return String(format: "%d'%02d''", paceMinutes, paceSeconds)
    }

    var accuracy: Int?
    var calories: Double

    /// 서버 세션에서 만들어진 세트면 그 세션 id (직접 추가한 운동은 nil)
    var sessionID: UUID? = nil
}

struct PostureFeedback: Identifiable {
    let id = UUID()

    let exerciseName: String
    let imageName: String
    let title: String
    let description: String
}

// MARK: - Main View

struct ExerciseAnalysisView: View {

    @Environment(\.dismiss) var dismiss

    let mintColor = Color.mintColor

    // Live 운동 결과 데이터
    let resultData: ExerciseResultData

    @State private var setData: [SetAnalysis]
    @State private var isAddingExercise = false

    // 서버 칼로리(caloriesBurned)가 나중에 도착해도 화면에 반영하기 위해 관찰
    @ObservedObject private var resultStore = ExerciseResultStore.shared

    init(resultData: ExerciseResultData = ExerciseResultData()) {
        self.resultData = resultData
        self._setData = State(initialValue: resultData.setAnalyses)
    }

    // MARK: - Calculated Values

    var totalCalories: Double {
        // 실제 세트 데이터가 있으면 세트별 칼로리 합산
        // 없으면 resultData의 총 칼로리를 사용
        if setData.isEmpty {
            return resultData.totalCalories
        }

        return setData.reduce(0) {
            $0 + $1.calories
        }
    }

    var formattedTotalDuration: String {

        let totalSecs = setData
            .compactMap { $0.totalSeconds }
            .reduce(0, +)

        if totalSecs > 0 {

            let hours = totalSecs / 3600
            let minutes = (totalSecs % 3600) / 60
            let seconds = totalSecs % 60

            if hours > 0 {
                return "\(hours)시간 \(minutes)분 \(seconds)초"
            } else if minutes > 0 {
                return "\(minutes)분 \(seconds)초"
            } else {
                return "\(seconds)초"
            }
        }

        return resultData.totalTime
    }

    // MARK: - Body

    var body: some View {

        VStack(spacing: 0) {

            // MARK: Header

            HStack {

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("자세 분석 및 기록 상세")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()

                // 좌우 균형을 위한 투명 버튼
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // MARK: Scroll Content

            ScrollView {

                VStack(spacing: 24) {

                    // MARK: 총 칼로리 / 운동 시간

                    VStack(spacing: 16) {

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("오늘의 총 소모 칼로리")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {

                                    Text(
                                        String(
                                            format: "%.1f",
                                            totalCalories
                                        )
                                    )
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(mintColor)

                                    Text("kcal")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }

                            Spacer()

                            Image(systemName: "flame.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                        }

                        Divider()

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("총 운동 시간")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)

                                Text(formattedTotalDuration)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            Spacer()

                            Image(systemName: "clock.fill")
                                .font(.system(size: 26))
                                .foregroundColor(mintColor)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // MARK: 전체 자세 점수

                    VStack(alignment: .leading, spacing: 14) {

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("전체 자세 점수")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)

                                Text("운동 중 측정된 자세 정확도")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            HStack(alignment: .firstTextBaseline, spacing: 2) {

                                Text("\(resultData.averageAccuracy)")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(mintColor)

                                Text("점")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }

                        // 점수 Progress Bar

                        GeometryReader { geometry in

                            ZStack(alignment: .leading) {

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 7)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(mintColor)
                                    .frame(
                                        width: geometry.size.width
                                            * CGFloat(
                                                min(
                                                    max(
                                                        resultData.averageAccuracy,
                                                        0
                                                    ),
                                                    100
                                                )
                                            )
                                            / 100,
                                        height: 7
                                    )
                            }
                        }
                        .frame(height: 7)

                        HStack {

                            Text("0")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)

                            Spacer()

                            Text("100")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // MARK: 운동 항목 및 세트별 분석

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {

                            Text("운동 항목 및 세트별 분석")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)

                            Spacer()

                            Button(action: {
                                isAddingExercise = true
                            }) {

                                HStack(spacing: 4) {

                                    Image(systemName: "plus.circle.fill")

                                    Text("운동 추가")
                                }
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .semibold
                                    )
                                )
                                .foregroundColor(mintColor)
                            }
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 10) {

                            ForEach(setData) { set in
                                SetAnalysisRow(
                                    data: set,
                                    mintColor: mintColor
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: 항목별 자세 점수 (서버 item_scores)

                    if !resultData.itemScores.isEmpty {

                        VStack(alignment: .leading, spacing: 12) {

                            Text("항목별 자세 점수")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)

                            VStack(spacing: 10) {

                                ForEach(resultData.itemScores) { item in

                                    VStack(alignment: .leading, spacing: 8) {

                                        HStack {
                                            Text(
                                                item.exerciseName.map { "\($0) · \(item.label)" }
                                                ?? item.label
                                            )
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.black)

                                            Spacer()

                                            Text("\(item.score)점")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray)
                                        }

                                        ProgressView(
                                            value: Double(min(max(item.score, 0), 100)),
                                            total: 100
                                        )
                                        .tint(mintColor)
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: AI 자세 피드백

                    VStack(alignment: .leading, spacing: 12) {

                        Text("AI 자세 피드백")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)

                        if resultData.feedbacks.isEmpty {

                            VStack(spacing: 8) {

                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(mintColor)

                                Text("등록된 자세 피드백이 없습니다.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(14)

                        } else {

                            VStack(spacing: 10) {

                                ForEach(resultData.feedbacks) { feedback in

                                    FeedbackRow(
                                        data: feedback,
                                        mintColor: mintColor
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }

            // MARK: 하단 확인 버튼

            Button(action: {
                dismiss()
            }) {

                Text("확인")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(mintColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            Color(
                red: 0.97,
                green: 0.97,
                blue: 0.97
            )
        )
        .navigationBarBackButtonHidden(true)

        // MARK: 운동 추가 Sheet

        .sheet(isPresented: $isAddingExercise) {

            AddExerciseSheet(
                setData: $setData,
                mintColor: mintColor
            )
        }

        // MARK: 누적 기록 / 서버 칼로리 갱신 반영
        // 세션에서 온 세트만 최신 값으로 교체하고, 직접 추가한 운동은 그대로 둔다.

        .onReceive(resultStore.$sessions) { sessions in

            guard !sessions.isEmpty else {
                return
            }

            let merged = ExerciseResultData.merged(from: sessions)
            let manual = setData.filter { $0.sessionID == nil }

            setData = merged.setAnalyses + manual
        }
    }
}

// MARK: - Set Analysis Row

struct SetAnalysisRow: View {

    let data: SetAnalysis
    let mintColor: Color

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            // 운동명 + 정확도

            HStack {

                Text("\(data.setNumber)세트 · ")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(mintColor)
                +
                Text(data.exerciseName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                if let accuracy = data.accuracy {

                    Text("정확도 \(accuracy)%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // 운동 상세 정보

            HStack {

                if data.category == .strength {

                    HStack(spacing: 6) {

                        if let weight = data.weight,
                           weight > 0 {

                            Text(
                                "\(String(format: "%.1f", weight))kg"
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.primary)
                        }

                        Text("\(data.completed ?? 0)")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.black)

                        Text("/ \(data.total ?? 0)회")
                            .font(
                                .system(
                                    size: 13,
                                    weight: .regular
                                )
                            )
                            .foregroundColor(.gray)
                    }

                } else {

                    HStack(spacing: 8) {

                        if let duration = data.durationString,
                           !duration.isEmpty {

                            Text(duration)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .bold
                                    )
                                )
                                .foregroundColor(.black)
                        }

                        if let dist = data.distanceKm,
                           dist > 0 {

                            Text(
                                "\(String(format: "%.2f", dist))km"
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.gray)

                            if let pace = data.calculatedPace {

                                Text("(페이스 \(pace))")
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundColor(mintColor)
                            }
                        }
                    }
                }

                Spacer()

                HStack(spacing: 2) {

                    Image(systemName: "flame")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)

                    Text(
                        String(
                            format: "%.1f kcal",
                            data.calories
                        )
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.orange)
                }
            }

            // 정확도 Progress Bar

            if let accuracy = data.accuracy {

                GeometryReader { geometry in

                    ZStack(alignment: .leading) {

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(mintColor)
                            .frame(
                                width: geometry.size.width
                                    * CGFloat(
                                        min(
                                            max(accuracy, 0),
                                            100
                                        )
                                    )
                                    / 100,
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }
}

// MARK: - Feedback Row

struct FeedbackRow: View {

    let data: PostureFeedback
    let mintColor: Color

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(
                        width: 60,
                        height: 60
                    )

                Image(systemName: data.imageName)
                    .font(.system(size: 28))
                    .foregroundColor(mintColor)
            }

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                HStack(spacing: 6) {

                    Text("[\(data.exerciseName)]")
                        .font(
                            .system(
                                size: 12,
                                weight: .bold
                            )
                        )
                        .foregroundColor(mintColor)

                    Text(data.title)
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.black)
                }

                Text(data.description)
                    .font(
                        .system(
                            size: 13,
                            weight: .regular
                        )
                    )
                    .foregroundColor(.gray)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
    }
}

// MARK: - Add Exercise Sheet

struct AddExerciseSheet: View {

    @Environment(\.dismiss) var dismiss

    @Binding var setData: [SetAnalysis]

    let mintColor: Color

    @State private var selectedCategory: ExerciseCategory = .strength

    @State private var exerciseName: String = ""
    @State private var weightStr: String = ""
    @State private var completedStr: String = ""
    @State private var totalStr: String = ""

    @State private var durationStr: String = ""
    @State private var distanceStr: String = ""

    @State private var caloriesStr: String = ""

    // MARK: 계산된 페이스

    var livePace: String? {

        let tempSet = SetAnalysis(
            exerciseName: "",
            category: .cardio,
            setNumber: 0,
            weight: nil,
            completed: nil,
            total: nil,
            durationString: durationStr,
            distanceKm: Double(distanceStr),
            accuracy: nil,
            calories: 0
        )

        return tempSet.calculatedPace
    }

    var body: some View {

        NavigationStack {

            Form {

                // MARK: 운동 종류

                Section(
                    header: Text("운동 종류 선택")
                        .foregroundColor(.black)
                ) {

                    Picker(
                        "운동 종류",
                        selection: $selectedCategory
                    ) {

                        ForEach(
                            ExerciseCategory.allCases
                        ) { category in

                            Text(category.rawValue)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: 운동 이름

                Section(
                    header: Text("운동 명칭")
                        .foregroundColor(.black)
                ) {

                    TextField(
                        selectedCategory == .strength
                        ? "예: 런지, 벤치프레스 등"
                        : "예: 러닝, 플랭크 등",
                        text: $exerciseName
                    )
                    .foregroundColor(.black)
                }

                // MARK: 웨이트

                if selectedCategory == .strength {

                    Section(
                        header: Text("웨이트 상세정보")
                            .foregroundColor(.black)
                    ) {

                        HStack {

                            Text("중량 (kg)")
                                .foregroundColor(.black)

                            Spacer()

                            TextField(
                                "(맨몸 운동 시 비워두세요)",
                                text: $weightStr
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black)
                        }

                        HStack {

                            Text("완료 횟수")
                                .foregroundColor(.black)

                            Spacer()

                            TextField(
                                "15",
                                text: $completedStr
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black)
                        }

                        HStack {

                            Text("목표 횟수")
                                .foregroundColor(.black)

                            Spacer()

                            TextField(
                                "15",
                                text: $totalStr
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black)
                        }
                    }

                } else {

                    // MARK: 유산소

                    Section(
                        header: Text("유산소 상세정보")
                            .foregroundColor(.black),

                        footer: Group {

                            if let pace = livePace {

                                HStack {

                                    Spacer()

                                    Text("⚡ 계산된 평균 페이스: ")
                                        .foregroundColor(.gray)
                                    +
                                    Text("\(pace) /km")
                                        .fontWeight(.bold)
                                        .foregroundColor(mintColor)
                                }
                                .padding(.top, 4)
                            }
                        }
                    ) {

                        HStack {

                            Text("운동 시간")
                                .foregroundColor(.black)

                            Spacer()

                            TextField(
                                "35:48",
                                text: $durationStr
                            )
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black)
                        }

                        HStack {

                            Text("운동 거리 (km)")
                                .foregroundColor(.black)

                            Spacer()

                            TextField(
                                "(선택) 5.32",
                                text: $distanceStr
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black)
                        }
                    }
                }

                // MARK: 칼로리

                Section(
                    header: Text("소모 칼로리")
                        .foregroundColor(.black)
                ) {

                    HStack {

                        Text("소모 칼로리 (kcal)")
                            .foregroundColor(.black)

                        Spacer()

                        TextField(
                            "500",
                            text: $caloriesStr
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.black)
                    }
                }
            }

            .navigationTitle("운동 기록 직접 추가")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("추가") {

                        let nextSetNumber =
                            (setData.map {
                                $0.setNumber
                            }.max() ?? 0) + 1

                        let weightVal =
                            Double(weightStr)

                        let parsedWeight =
                            (
                                weightVal != nil &&
                                weightVal! > 0
                            )
                            ? weightVal
                            : nil

                        let newSet = SetAnalysis(

                            exerciseName:
                                exerciseName.isEmpty
                                ? (
                                    selectedCategory == .strength
                                    ? "자율 근력운동"
                                    : "자율 유산소"
                                )
                                : exerciseName,

                            category: selectedCategory,

                            setNumber: nextSetNumber,

                            weight: parsedWeight,

                            completed:
                                Int(completedStr) ?? 15,

                            total:
                                Int(totalStr) ?? 15,

                            durationString:
                                durationStr.isEmpty
                                ? nil
                                : durationStr,

                            distanceKm:
                                Double(distanceStr),

                            accuracy: nil,

                            calories:
                                Double(caloriesStr) ?? 50.0
                        )

                        setData.append(newSet)

                        dismiss()
                    }
                    .foregroundColor(mintColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        ExerciseAnalysisView()
    }
}
