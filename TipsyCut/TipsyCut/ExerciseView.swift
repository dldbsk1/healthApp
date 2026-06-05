//
//  ExerciseView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//
import SwiftUI

struct ExerciseView: View {
    
    @State private var path = NavigationPath()
    @State private var goToAnalysis = false
    
    let exercises: [Exercise]
    let end_result: () -> Void
    
    // 앱 메인 컬러 (민트)
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    init(end_result: @escaping () -> Void) {
        self.end_result = end_result
        self.exercises = Exercise.recommendedList
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 상단 인사 문구
                    VStack(alignment: .leading, spacing: 8) {
                        Text("운동")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("오늘도 함께 건강한 하루 보내봐요! 💪")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        /*Text("건강한 하루 보내봐요! 💪")
                            .font(.subheadline)
                            .foregroundColor(.secondary)*/
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
                                
                                // 🖼️ 운동 사진
                                Image(exercise.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                // 운동 이름 + 카테고리
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(exercise.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text(exercise.category)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Let's Go 버튼
                                Button(action: {
                                    path.append(LiveDestination(name: exercise.name))
                                }) {
                                    VStack(spacing: 2) {
                                        Text("Let's")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                        Text("Go")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
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
                    
                    // 운동 분석 하러 가기 버튼
                    Button(action: {
                        goToAnalysis = true
                    }) {
                        Text("운동 분석 하러 가기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(mintColor)
                            //.background(.mintColor)
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationDestination(for: String.self) { exerciseName in
                ExerciseContentView(exerciseName: exerciseName, path: $path)
            }
            .navigationDestination(for: LiveDestination.self) { destination in
                ExerciseLiveView(exerciseName: destination.name, path: $path)
            }
            .navigationDestination(isPresented: $goToAnalysis) {
                ExerciseAnalysisView()
            }
        }
    }
}

// LiveView로 이동할 때 쓸 타입
struct LiveDestination: Hashable {
    let name: String
}

#Preview {
    ExerciseView(end_result: {})
}
