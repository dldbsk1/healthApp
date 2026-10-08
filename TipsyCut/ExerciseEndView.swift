//
//  ExerciseEndView.swift
//  TipsyCut
//
//  Created by mac16 on 5/27/26.
//

import SwiftUI

struct ExerciseEndView: View {

    // 앱 메인 컬러
    let mintColor = Color.mintColor

    // 부모의 NavigationPath
    @Binding var path: NavigationPath

    // 운동 데이터
    let exercise: Exercise

    let totalTime: String

    let totalCalories: Int

    let accuracy: Int

    let setCount: Int

    let repsPerSet: Int

    let itemScores: [ExerciseItemScore]

    let feedbacks: [ExerciseFeedback]

    // ★ 추가: 분석 화면으로 넘길 결과 데이터
    let resultData: ExerciseResultData

    // 플랭크처럼 "횟수"가 아니라 "유지 시간(초)"를 보여줘야 하는 운동인지
    let isHold: Bool

    // Spring Boot가 계산한 실제 칼로리가 나중에 도착하면 여기서도 반영
    @ObservedObject private var resultStore = ExerciseResultStore.shared

    // 이 세션의 칼로리: 서버(caloriesBurned)가 확정해 주면 그 값, 아니면 전달받은 추정값
    private var currentSession: ExerciseResultData? {
        resultStore.session(id: resultData.id)
    }

    private var displayedCalories: Int {
        if let session = currentSession {
            return Int(session.totalCalories.rounded())
        }
        return totalCalories
    }

    private var isCaloriesFinal: Bool {
        currentSession?.caloriesFromServer ?? false
    }

    /// 운동량 표시 문구
    /// - 플랭크 같은 유지형 운동: "1분 30초" (repsPerSet = 버틴 초)
    /// - 그 외: "15회 × 1세트"
    private var repsText: String {
        if isHold {
            let minutes = repsPerSet / 60
            let seconds = repsPerSet % 60
            return "\(minutes)분 \(seconds)초"
        }
        return "\(repsPerSet)회 × \(setCount)세트"
    }

    // =============================================================
    // 초기화
    // =============================================================

    init(
        path: Binding<NavigationPath>,
        exercise: Exercise = Exercise.recommendedList[0],
        totalTime: String = "00:00:01",
        totalCalories: Int = 1,
        accuracy: Int = 1,
        setCount: Int = 1,
        repsPerSet: Int = 1,
        itemScores: [ExerciseItemScore] = [],
        feedbacks: [ExerciseFeedback] = [],
        resultData: ExerciseResultData = ExerciseResultData(),   // ★ 추가
        isHold: Bool = false
    ) {

        self._path = path

        self.exercise = exercise

        self.totalTime = totalTime

        self.totalCalories = totalCalories

        self.accuracy = accuracy

        self.setCount = setCount

        self.repsPerSet = repsPerSet

        self.itemScores = itemScores

        self.feedbacks = feedbacks

        self.resultData = resultData   // ★ 추가

        self.isHold = isHold
    }

    // 메인 컬러
    let mainGreen =
        Color(
            red: 0.40,
            green: 0.65,
            blue: 0.50
        )

    var body: some View {

        ZStack {

            // =====================================================
            // 배경
            // =====================================================

            Color(
                red: 0.97,
                green: 0.97,
                blue: 0.97
            )
            .ignoresSafeArea()

            // 컨페티
            ConfettiBackground()

            VStack(spacing: 0) {

                ScrollView {

                    VStack(spacing: 28) {

                        // =================================================
                        // 완료 체크 아이콘
                        // =================================================

                        ZStack {

                            Circle()
                                .fill(mintColor)
                                .frame(
                                    width: 60,
                                    height: 60
                                )

                            Image(
                                systemName: "checkmark"
                            )
                            .font(
                                .system(
                                    size: 36,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // =================================================
                        // 완료 메시지
                        // =================================================

                        VStack(spacing: 8) {

                            Text("운동 완료!")
                                .font(
                                    .system(
                                        size: 26,
                                        weight: .bold
                                    )
                                )
                                .foregroundColor(.black)

                            Text("오늘도 수고했어요 💪")
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .regular
                                    )
                                )
                                .foregroundColor(.gray)
                        }

                        // =================================================
                        // 운동 요약 카드
                        // =================================================

                        VStack(spacing: 20) {

                            // 운동 시간
                            VStack(spacing: 8) {

                                Text("운동 시간")
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .regular
                                        )
                                    )
                                    .foregroundColor(.gray)

                                Text(totalTime)
                                    .font(
                                        .system(
                                            size: 32,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 8)

                            Divider()
                                .padding(.horizontal, 8)

                            // 칼로리 + 정확도
                            HStack(spacing: 0) {

                                // 총 칼로리
                                VStack(spacing: 8) {

                                    Text(isCaloriesFinal ? "총 칼로리" : "총 칼로리 (계산 중)")
                                        .font(
                                            .system(
                                                size: 13,
                                                weight: .regular
                                            )
                                        )
                                        .foregroundColor(.gray)

                                    HStack(
                                        alignment: .bottom,
                                        spacing: 2
                                    ) {

                                        Text(
                                            "\(displayedCalories)"
                                        )
                                        .font(
                                            .system(
                                                size: 22,
                                                weight: .bold
                                            )
                                        )
                                        .foregroundColor(.black)

                                        Text("kcal")
                                            .font(
                                                .system(
                                                    size: 13,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .frame(
                                    maxWidth: .infinity
                                )

                                // 구분선
                                Rectangle()
                                    .fill(
                                        Color.gray.opacity(0.2)
                                    )
                                    .frame(
                                        width: 1,
                                        height: 40
                                    )

                                // 정확도
                                VStack(spacing: 8) {

                                    Text("정확도")
                                        .font(
                                            .system(
                                                size: 13,
                                                weight: .regular
                                            )
                                        )
                                        .foregroundColor(.gray)

                                    HStack(
                                        alignment: .bottom,
                                        spacing: 2
                                    ) {

                                        Text(
                                            "\(accuracy)"
                                        )
                                        .font(
                                            .system(
                                                size: 22,
                                                weight: .bold
                                            )
                                        )
                                        .foregroundColor(.black)

                                        Text("%")
                                            .font(
                                                .system(
                                                    size: 13,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .frame(
                                    maxWidth: .infinity
                                )
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // =================================================
                        // 오늘의 운동
                        // =================================================

                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {

                            Text("오늘의 운동")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .semibold
                                    )
                                )
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)

                            HStack(spacing: 14) {

                                // 운동 이미지
                                ZStack {

                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                    .fill(
                                        Color.gray.opacity(0.1)
                                    )
                                    .frame(
                                        width: 60,
                                        height: 60
                                    )

                                    Image(
                                        systemName:
                                            "figure.strengthtraining.functional"
                                    )
                                    .font(
                                        .system(size: 28)
                                    )
                                    .foregroundColor(
                                        mainGreen
                                    )
                                }

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(exercise.name)
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundColor(.black)

                                    Text(repsText)
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .regular
                                        )
                                    )
                                    .foregroundColor(.gray)
                                }

                                Spacer()
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 20)
                }

                // =====================================================
                // 하단 버튼 영역
                // =====================================================

                // ★ 수정: 분석 화면 링크 + 홈 버튼
                VStack(spacing: 10) {


                    Button(action: {

                        // ExerciseView로 돌아감
                        path = NavigationPath()

                    }) {

                        Text("운동 홈으로")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(mintColor)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// =============================================================
// 컨페티 배경
// =============================================================

struct ConfettiBackground: View {

    let confettiColors: [Color] = [

        Color(
            red: 0.40,
            green: 0.65,
            blue: 0.50
        ),

        Color(
            red: 1.0,
            green: 0.85,
            blue: 0.40
        ),

        Color(
            red: 1.0,
            green: 0.65,
            blue: 0.65
        ),

        Color(
            red: 0.60,
            green: 0.80,
            blue: 0.95
        ),

        Color(
            red: 0.95,
            green: 0.70,
            blue: 0.50
        )
    ]

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                ForEach(
                    0..<25,
                    id: \.self
                ) { index in

                    ConfettiPiece(

                        color:
                            confettiColors[
                                index
                                % confettiColors.count
                            ],

                        size:
                            CGFloat.random(
                                in: 6...12
                            )
                    )
                    .position(

                        x:
                            CGFloat.random(in:20...(geometry.size.width - 20)
                            ),

                        y:
                            CGFloat.random(
                                in: 80...400
                            )
                    )
                    .rotationEffect(
                        .degrees(
                            Double.random(
                                in: 0...360
                            )
                        )
                    )
                }
            }
        }
    }
}

// =============================================================
// 컨페티 조각
// =============================================================

struct ConfettiPiece: View {

    let color: Color

    let size: CGFloat

    var body: some View {

        Rectangle()
            .fill(color)
            .frame(
                width: size,
                height: size
            )
            .rotationEffect(
                .degrees(45)
            )
            .opacity(0.85)
    }
}

// =============================================================
// Preview
// =============================================================

#Preview {

    NavigationStack {

        ExerciseEndView(
            path:
                .constant(
                    NavigationPath()
                )
        )
    }
}
