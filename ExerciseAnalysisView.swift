//
//  ExerciseAnalysisView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//

import SwiftUI

// MARK: - Exercise Category Enum

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case strength = "웨이트"
    case cardio = "유산소"
    
    var id: String { self.rawValue }
}

// MARK: - Data Models

struct SetAnalysis: Identifiable {
    let id = UUID()
    var exerciseName: String       // 운동 이름
    var category: ExerciseCategory // 운동 카테고리 (웨이트 vs 유산소)
    var setNumber: Int             // 세트 번호
    
    // 웨이트 용 데이터
    var weight: Double?            // 중량 (kg) - nil이거나 0이면 화면에 kg를 표시하지 않음
    var completed: Int?            // 완료 횟수
    var total: Int?                // 목표 횟수
    
    // 유산소 용 데이터 (자유 입력 방식)
    var durationString: String?    // 시간 문자열 (예: "1:05:45", "32:48", "15" 등)
    var distanceKm: Double?        // 운동 거리 (km, 예: 3.05)
    
    // 연산 프로퍼티: 시간 문자열을 총 초(second) 단위로 파싱
    var totalSeconds: Int? {
        guard let str = durationString?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty else { return nil }
        let components = str.split(separator: ":").compactMap { Int($0) }
        
        if components.count == 3 {
            // HH:MM:SS
            return components[0] * 3600 + components[1] * 60 + components[2]
        } else if components.count == 2 {
            // MM:SS
            return components[0] * 60 + components[1]
        } else if components.count == 1 {
            // 숫자만 있는 경우 -> 분 단위
            return components[0] * 60
        }
        return nil
    }
    
    // 연산 프로퍼티: 평균 페이스 계산 (예: 7'11'')
    var calculatedPace: String? {
        guard let seconds = totalSeconds, seconds > 0,
              let dist = distanceKm, dist > 0 else { return nil }
        
        let paceInSecondsPerKm = Int(Double(seconds) / dist)
        let paceMinutes = paceInSecondsPerKm / 60
        let paceSeconds = paceInSecondsPerKm % 60
        
        return String(format: "%d'%02d''", paceMinutes, paceSeconds)
    }
    
    var accuracy: Int?             // 자세 정확도 (%)
    var calories: Double           // 해당 세트 소모 칼로리 (kcal)
}

struct PostureFeedback: Identifiable {
    let id = UUID()
    let exerciseName: String       // 피드백 대상 운동
    let imageName: String
    let title: String
    let description: String
}

// MARK: - Main View

struct ExerciseAnalysisView: View {
    let mintColor = Color.mintColor

    // 세트별 분석 데이터
    @State private var setData: [SetAnalysis] = [
        SetAnalysis(exerciseName: "니푸쉬업", category: .strength, setNumber: 1, weight: nil, completed: 15, total: 15, accuracy: 90, calories: 12.5),
        SetAnalysis(exerciseName: "런지", category: .strength, setNumber: 2, weight: nil, completed: 12, total: 15, accuracy: 93, calories: 18.0),
        SetAnalysis(exerciseName: "레그레이즈", category: .strength, setNumber: 3, weight: nil, completed: 15, total: 15, accuracy: 88, calories: 10.2),
        SetAnalysis(exerciseName: "플랭크", category: .cardio, setNumber: 4, durationString: "1:00", distanceKm: nil, accuracy: 95, calories: 15.0),
        SetAnalysis(exerciseName: "러닝머신", category: .cardio, setNumber: 5, durationString: "32:48", distanceKm: 4.58, accuracy: nil, calories: 245.0)
    ]
    
    // 직접 운동 추가 모달 제어
    @State private var isAddingExercise = false
    
    // 자세 피드백 데이터
    let feedbackData: [PostureFeedback] = [
        PostureFeedback(
            exerciseName: "니푸쉬업",
            imageName: "figure.strengthtraining.functional",
            title: "좋았어요!",
            description: "상체를 내릴 때 코어에 힘을 주고, 허리가 아래로 꺼지지 않도록 고정해 주세요."
        ),
        PostureFeedback(
            exerciseName: "런지",
            imageName: "figure.cooldown",
            title: "개선하면 좋아요",
            description: "무릎이 안쪽으로 말리지 않게 주의하고, 앞발 뒤꿈치에 체중을 살려 하체를 지탱해 주세요."
        ),
        PostureFeedback(
            exerciseName: "레그레이즈",
            imageName: "figure.mind.and.body",
            title: "다음엔 더 잘할 수 있어요!",
            description: "다리를 내릴 때 허리가 들리지 않도록 복근의 힘으로 수건 한 장 들뜸 없이 눌러주세요."
        )
    ]
    
    // 연산 프로퍼티: 총 소모 칼로리 계산
    var totalCalories: Double {
        setData.reduce(0) { $0 + $1.calories }
    }
    
    // 연산 프로퍼티: 총 운동 시간 계산
    var formattedTotalDuration: String {
        let totalSecs = setData.compactMap { $0.totalSeconds }.reduce(0, +)
        if totalSecs == 0 { return "0분" }
        
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

    var body: some View {
        VStack(spacing: 0) {
            // 상단 네비게이션 헤더
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Text("자세 분석 및 기록 상세")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 총 운동 소모 칼로리 및 총 운동 시간 요약 카드
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("오늘의 총 소모 칼로리")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", totalCalories))
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

                    // 세트별 분석 섹션
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
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(mintColor)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 10) {
                            ForEach(setData) { set in
                                SetAnalysisRow(data: set, mintColor: mintColor)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 자세 피드백 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI 자세 피드백")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 10) {
                            ForEach(feedbackData) { feedback in
                                FeedbackRow(data: feedback, mintColor: mintColor)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            
            // 하단 버튼
            NavigationLink(destination: ExerciseView(end_result: {})) {
                Text("홈으로 가기")
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
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .sheet(isPresented: $isAddingExercise) {
            AddExerciseSheet(setData: $setData, mintColor: mintColor)
        }
    }
}

// MARK: - Row Views

struct SetAnalysisRow: View {
    let data: SetAnalysis
    let mintColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            HStack {
                if data.category == .strength {
                    HStack(spacing: 6) {
                        if let weight = data.weight, weight > 0 {
                            Text("\(String(format: "%.1f", weight))kg")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("\(data.completed ?? 0)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        Text("/ \(data.total ?? 0)회")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                } else {
                    HStack(spacing: 8) {
                        if let duration = data.durationString, !duration.isEmpty {
                            Text(duration)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        if let dist = data.distanceKm, dist > 0 {
                            Text("\(String(format: "%.2f", dist))km")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            if let pace = data.calculatedPace {
                                Text("(페이스 \(pace))")
                                    .font(.system(size: 13, weight: .medium))
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
                    Text(String(format: "%.1f kcal", data.calories))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            
            if let accuracy = data.accuracy {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(mintColor)
                            .frame(width: geometry.size.width * CGFloat(accuracy) / 100, height: 3)
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

struct FeedbackRow: View {
    let data: PostureFeedback
    let mintColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: data.imageName)
                    .font(.system(size: 28))
                    .foregroundColor(mintColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("[\(data.exerciseName)]")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(mintColor)
                    Text(data.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Text(data.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
    }
}

// MARK: - Exercise Custom Add Sheet

struct AddExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var setData: [SetAnalysis]
    let mintColor: Color
    
    @State private var selectedCategory: ExerciseCategory = .strength
    @State private var exerciseName: String = ""
    
    // 입력 필드 변수들 (기본값 빈 문자열로 시작)
    @State private var weightStr: String = ""
    @State private var completedStr: String = ""
    @State private var totalStr: String = ""
    @State private var durationStr: String = ""
    @State private var distanceStr: String = ""
    @State private var caloriesStr: String = ""
    
    var livePace: String? {
        let tempSet = SetAnalysis(
            exerciseName: "",
            category: .cardio,
            setNumber: 0,
            durationString: durationStr,
            distanceKm: Double(distanceStr),
            calories: 0
        )
        return tempSet.calculatedPace
    }

    var body: some View {
        NavigationStack {
            Form {
                // 1. 운동 종류 선택
                Section(header: Text("운동 종류 선택").foregroundColor(.black)) {
                    Picker("운동 종류", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 2. 운동 이름
                Section(header: Text("운동 명칭").foregroundColor(.black)) {
                    TextField(
                        selectedCategory == .strength ? "예: 런지, 벤치프레스 등" : "예: 러닝, 플랭크 등",
                        text: $exerciseName
                    )
                    .foregroundColor(.black) // 입력된 텍스트는 검정색
                }
                
                // 3. 종류별 입력 폼
                if selectedCategory == .strength {
                    Section(header: Text("웨이트 상세정보").foregroundColor(.black)) {
                        HStack {
                            Text("중량 (kg)")
                                .foregroundColor(.black) // 고정 라벨 검정색
                            Spacer()
                            TextField("(맨몸 운동 시 비워두세요)", text: $weightStr)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black) // 입력 값 검정색
                        }
                        
                        HStack {
                            Text("완료 횟수")
                                .foregroundColor(.black) // 고정 라벨 검정색
                            Spacer()
                            TextField("15", text: $completedStr)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black) // 입력 값 검정색
                        }
                        
                        HStack {
                            Text("목표 횟수")
                                .foregroundColor(.black) // 고정 라벨 검정색
                            Spacer()
                            TextField("15", text: $totalStr)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black) // 입력 값 검정색
                        }
                    }
                } else {
                    Section(
                        header: Text("유산소 상세정보").foregroundColor(.black),
                        footer: Group {
                            if let pace = livePace {
                                HStack {
                                    Spacer()
                                    Text("⚡️️ 계산된 평균 페이스: ")
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
                                .foregroundColor(.black) // 고정 라벨 검정색
                            Spacer()
                            TextField("35:48", text: $durationStr)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black) // 입력 값 검정색
                        }
                        
                        HStack {
                            Text("운동 거리 (km)")
                                .foregroundColor(.black) // 고정 라벨 검정색
                            Spacer()
                            TextField("(선택) 5.32", text: $distanceStr)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.black) // 입력 값 검정색
                        }
                    }
                }
                
                // 4. 소모 칼로리 입력
                Section(header: Text("소모 칼로리").foregroundColor(.black)) {
                    HStack {
                        Text("소모 칼로리 (kcal)")
                            .foregroundColor(.black) // 고정 라벨 검정색
                        Spacer()
                        TextField("500", text: $caloriesStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.black) // 입력 값 검정색
                    }
                }
            }
            .navigationTitle("운동 기록 직접 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let nextSetNumber = (setData.map { $0.setNumber }.max() ?? 0) + 1
                        
                        let weightVal = Double(weightStr)
                        let parsedWeight = (weightVal != nil && weightVal! > 0) ? weightVal : nil
                        
                        let newSet = SetAnalysis(
                            exerciseName: exerciseName.isEmpty ? (selectedCategory == .strength ? "자율 근력운동" : "자율 유산소") : exerciseName,
                            category: selectedCategory,
                            setNumber: nextSetNumber,
                            weight: parsedWeight,
                            completed: Int(completedStr) ?? 15,
                            total: Int(totalStr) ?? 15,
                            durationString: durationStr.isEmpty ? nil : durationStr,
                            distanceKm: Double(distanceStr),
                            accuracy: nil,
                            calories: Double(caloriesStr) ?? 50.0
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

#Preview {
    NavigationStack {
        ExerciseAnalysisView()
    }
}
