//
//  ExerciseView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//  ⚠️ "AI 카메라 측정" 플로팅 버튼 비활성화
//

import SwiftUI

struct ExerciseView: View {

    @State private var path = NavigationPath()

    @State private var goToAnalysis = false

    @ObservedObject private var resultStore = ExerciseResultStore.shared

    let exercises: [Exercise]
    let end_result: () -> Void

    // 앱 메인 컬러 (민트)
    let mintColor = Color.mintColor

    init(end_result: @escaping () -> Void) {
        self.end_result = end_result
        self.exercises = Exercise.recommendedList
    }

    var body: some View {

        NavigationStack(path: $path) {

            ZStack(alignment: .bottomTrailing) {

                ScrollView {

                    VStack(spacing: 16) {

                        // 상단 인사 문구
                        VStack(alignment: .leading, spacing: 8) {

                            Text("움직여볼까요?")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("AI가 자세를 잡아줘요! ")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                        // 추천 운동 헤더
                        HStack {

                            Text("추천 운동")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 운동 리스트
                        ForEach(exercises) { exercise in

                            NavigationLink(value: exercise.name) {

                                HStack(spacing: 14) {

                                    // 운동 사진
                                    Image(exercise.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(
                                            width: 120,
                                            height: 80
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 12
                                            )
                                        )

                                    // 운동 이름 + 카테고리
                                    VStack(
                                        alignment: .leading,
                                        spacing: 6
                                    ) {

                                        Text(exercise.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)

                                        Text(exercise.category)
                                            .font(.subheadline)
                                            .foregroundColor(
                                                Color(.systemGray2)
                                            )
                                    }

                                    Spacer()

                                    // Let's Go 버튼
                                    Button(action: {

                                        path.append(
                                            LiveDestination(
                                                name: exercise.name
                                            )
                                        )

                                    }) {

                                        VStack(spacing: 2) {

                                            Text("Let's")
                                                .font(
                                                    .system(
                                                        size: 14,
                                                        weight: .bold,
                                                        design: .rounded
                                                    )
                                                )

                                            Text("Go")
                                                .font(
                                                    .system(
                                                        size: 16,
                                                        weight: .bold,
                                                        design: .rounded
                                                    )
                                                )
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(mintColor)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(
                                        PlainButtonStyle()
                                    )
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    Color(.systemGray6)
                                )
                                .cornerRadius(14)
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 20)

                        // =====================================================
                        // 운동 분석 하러 가기
                        // =====================================================

                        Button(action: {

                            // 서버에서 받은 최신 분석 결과가 있는 경우
                            // 그 데이터를 가지고 분석 화면으로 이동
                            if resultStore.accumulatedResultData != nil {
                                goToAnalysis = true
                            }

                        }) {

                            Text("운동 분석 하러 가기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    resultStore.accumulatedResultData == nil
                                    ? Color.gray
                                    : mintColor
                                )
                                .cornerRadius(14)
                                .padding(.horizontal)
                        }
                        .disabled(
                            resultStore.accumulatedResultData == nil
                        )
                        .padding(.bottom)
                    }
                }

                // =============================================================
                // 카메라 플로팅 버튼
                // 현재 비활성화
                // =============================================================

                /*
                Button(action: {

                    path.append(
                        LiveDestination(
                            name: "AI 카메라 측정"
                        )
                    )

                }) {

                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(
                            width: 60,
                            height: 60
                        )
                        .background(mintColor)
                        .clipShape(Circle())
                        .shadow(
                            color: .black.opacity(0.25),
                            radius: 6,
                            x: 0,
                            y: 4
                        )
                }
                .padding(.trailing, 24)
                .padding(.bottom, 85)
                */
            }
            .background(
                Color.white.ignoresSafeArea()
            )

            // =============================================================
            // ExerciseContentView
            // =============================================================

            .navigationDestination(
                for: String.self
            ) { exerciseName in

                ExerciseContentView(
                    exerciseName: exerciseName,
                    path: $path
                )
            }

            // =============================================================
            // ExerciseLiveView
            // =============================================================

            .navigationDestination(
                for: LiveDestination.self
            ) { destination in

                ExerciseLiveView(
                    exerciseName: destination.name,
                    path: $path
                )
            }

            // =============================================================
            // ExerciseAnalysisView
            // =============================================================

            .navigationDestination(
                isPresented: $goToAnalysis
            ) {

                if let resultData =
                    resultStore.accumulatedResultData {

                    ExerciseAnalysisView(
                        resultData: resultData
                    )

                } else {

                    ExerciseAnalysisView()
                }
            }
        }
    }
}

// =============================================================
// LiveView로 이동할 때 사용할 타입
// =============================================================

struct LiveDestination: Hashable {

    let name: String
}

#Preview {

    ExerciseView(
        end_result: {}
    )
}
