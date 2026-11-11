import SwiftUI

struct ExerciseView: View {

    @State private var path = NavigationPath()
    @State private var goToAnalysis = false
    @State private var isAddingExercise = false

    @ObservedObject private var resultStore = ExerciseResultStore.shared

    let exercises: [Exercise]
    let end_result: () -> Void

    // 앱 메인 컬러
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

                            Text("AI가 자세를 잡아줘요!")
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

                        // 추천 운동 목록
                        ForEach(exercises) { exercise in

                            NavigationLink(value: exercise.name) {

                                HStack(spacing: 14) {

                                    Image(exercise.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 80)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )

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

                                    Button {
                                        path.append(
                                            LiveDestination(name: exercise.name)
                                        )
                                    } label: {

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
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(14)
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 20)

                        // 운동 분석 버튼
                        Button {

                            if resultStore.hasAnyRecord {
                                goToAnalysis = true
                            }

                        } label: {

                            Text("운동 분석 하러 가기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    !resultStore.hasAnyRecord
                                    ? Color.gray
                                    : mintColor
                                )
                                .cornerRadius(14)
                                .padding(.horizontal)
                        }
                        .disabled(
                            !resultStore.hasAnyRecord
                        )
                        .padding(.bottom, 12)
                    }
                }

                // 직접 운동 추가 플로팅 버튼
                Button {
                    isAddingExercise = true
                } label: {

                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))

                        Text("운동 기록 추가")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(mintColor)
                    .clipShape(Capsule())
                    .shadow(
                        color: .black.opacity(0.18),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 60) // 기존 28 → +32pt (약 0.5cm 위로)
            }
            .background(Color.white.ignoresSafeArea())

            // 운동 콘텐츠 화면
            .navigationDestination(for: String.self) { exerciseName in
                ExerciseContentView(
                    exerciseName: exerciseName,
                    path: $path
                )
            }

            // 실시간 운동 화면
            .navigationDestination(for: LiveDestination.self) { destination in
                ExerciseLiveView(
                    exerciseName: destination.name,
                    path: $path
                )
            }

            // 운동 완료 화면 (path 방식)
            .navigationDestination(for: EndViewData.self) { data in
                ExerciseEndView(
                    path: $path,
                    exercise: data.exercise,
                    totalTime: data.totalTime,
                    totalCalories: data.totalCalories,
                    accuracy: data.accuracy,
                    setCount: data.setCount,
                    repsPerSet: data.repsPerSet,
                    resultData: data.resultData,
                    isHold: data.isHold,
                    onGoHome: {
                        // path 맨 위 = [..., LiveView, EndView]
                        // 두 개를 pop → 운동 시작 전 화면(ContentView 또는 목록)
                        path.removeLast(min(2, path.count))
                    }
                )
            }

            // 운동 분석 화면
            .navigationDestination(isPresented: $goToAnalysis) {

                if let resultData = resultStore.accumulatedResultData {
                    ExerciseAnalysisView(resultData: resultData)
                } else {
                    // AI 세션 없이 직접 추가한 기록만 있는 경우
                    ExerciseAnalysisView(resultData: ExerciseResultData(
                        exerciseName: "직접 기록",
                        totalTime: "00:00",
                        totalCalories: 0,
                        averageAccuracy: 0,
                        setCount: 0,
                        repsPerSet: 0,
                        setAnalyses: [],
                        feedbacks: [],
                        itemScores: []
                    ))
                }
            }

            // 운동 직접 추가 화면
            .sheet(isPresented: $isAddingExercise) {
                AddExerciseSheet(mintColor: mintColor) { newSet in
                    resultStore.addManual(newSet)
                }
            }
        }
    }
}

// 실시간 운동 화면 이동에 사용할 타입
struct LiveDestination: Hashable {
    let name: String
}

#Preview {
    ExerciseView(end_result: {})
}
