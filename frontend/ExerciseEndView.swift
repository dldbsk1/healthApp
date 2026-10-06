//
//  ExerciseEndView.swift
//  TipsyCut
//
//  Created by mac16 on 5/27/26.
//

import SwiftUI

struct ExerciseEndView: View {
    
    // 앱 메인 컬러 (민트)
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    // 부모의 NavigationPath를 받아옴
    @Binding var path: NavigationPath
    
    // 외부에서 주입받을 데이터
    let exercise: Exercise
    let totalTime: String
    let totalCalories: Int
    let accuracy: Int
    let setCount: Int
    let repsPerSet: Int
    
    // 기본값 (Preview용)
    init(
        path: Binding<NavigationPath>,
        exercise: Exercise = Exercise.recommendedList[0],
        totalTime: String = "00:45:28",
        totalCalories: Int = 238,
        accuracy: Int = 92,
        setCount: Int = 3,
        repsPerSet: Int = 15
    ) {
        self._path = path
        self.exercise = exercise
        self.totalTime = totalTime
        self.totalCalories = totalCalories
        self.accuracy = accuracy
        self.setCount = setCount
        self.repsPerSet = repsPerSet
    }
    
    // 메인 컬러
    let mainGreen = Color(red: 0.40, green: 0.65, blue: 0.50)
    
    var body: some View {
        ZStack {
            // 배경
            Color(red: 0.97, green: 0.97, blue: 0.97)
                .ignoresSafeArea()
            
            // 컨페티 배경 (장식)
            ConfettiBackground()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        
                        // MARK: - 완료 체크 아이콘
                        ZStack {
                            Circle()
                                .fill(mintColor)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // MARK: - 완료 메시지
                        VStack(spacing: 8) {
                            Text("운동 완료!")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("오늘도 수고했어요 💪")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        // MARK: - 운동 요약 카드
                        VStack(spacing: 20) {
                            // 운동 시간
                            VStack(spacing: 8) {
                                Text("운동 시간")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.gray)
                                
                                Text(totalTime)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 8)
                            
                            Divider()
                                .padding(.horizontal, 8)
                            
                            // 칼로리 + 정확도
                            HStack(spacing: 0) {
                                // 총 칼로리
                                VStack(spacing: 8) {
                                    Text("총 칼로리")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                    
                                    HStack(alignment: .bottom, spacing: 2) {
                                        Text("\(totalCalories)")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Text("kcal")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // 구분선
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 1, height: 40)
                                
                                // 정확도
                                VStack(spacing: 8) {
                                    Text("정확도")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                    
                                    HStack(alignment: .bottom, spacing: 2) {
                                        Text("\(accuracy)")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Text("%")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // MARK: - 오늘의 운동
                        VStack(alignment: .leading, spacing: 12) {
                            Text("오늘의 운동")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 14) {
                                // 운동 이미지
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "figure.strengthtraining.functional")
                                        .font(.system(size: 28))
                                        .foregroundColor(mainGreen)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    Text("\(repsPerSet)회  ×  \(setCount)세트")
                                        .font(.system(size: 13, weight: .regular))
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
                
                // MARK: - 하단 운동 완료 버튼
                Button(action: {
                    // path를 비워서 모든 화면 닫고 ExerciseView로 돌아감
                    path = NavigationPath()
                }) {
                    Text("운동홈으로")
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
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - 컨페티 배경 (장식용)
struct ConfettiBackground: View {
    
    // 컨페티 색상
    let confettiColors: [Color] = [
        Color(red: 0.40, green: 0.65, blue: 0.50),    // 그린
        Color(red: 1.0, green: 0.85, blue: 0.40),     // 옐로우
        Color(red: 1.0, green: 0.65, blue: 0.65),     // 핑크
        Color(red: 0.60, green: 0.80, blue: 0.95),    // 블루
        Color(red: 0.95, green: 0.70, blue: 0.50)     // 오렌지
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<25, id: \.self) { index in
                    ConfettiPiece(
                        color: confettiColors[index % confettiColors.count],
                        size: CGFloat.random(in: 6...12)
                    )
                    .position(
                        x: CGFloat.random(in: 20...(geometry.size.width - 20)),
                        y: CGFloat.random(in: 80...400)
                    )
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                }
            }
        }
    }
}

// MARK: - 컨페티 조각
struct ConfettiPiece: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        // 마름모 / 다이아몬드 모양
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .opacity(0.85)
    }
}

#Preview {
    NavigationStack {
        ExerciseEndView(path: .constant(NavigationPath()))
    }
}
