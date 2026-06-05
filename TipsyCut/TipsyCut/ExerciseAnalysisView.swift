//
//  ExerciseAnalysisView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//

import SwiftUI

struct ExerciseAnalysisView: View {
    
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    // 세트별 데이터
    let setData: [SetAnalysis] = [
        SetAnalysis(setNumber: 1, completed: 15, total: 15, accuracy: 90),
        SetAnalysis(setNumber: 2, completed: 15, total: 15, accuracy: 93),
        SetAnalysis(setNumber: 3, completed: 15, total: 15, accuracy: 92)
    ]
    
    // 자세 피드백 데이터
    let feedbackData: [PostureFeedback] = [
        PostureFeedback(
            imageName: "figure.strengthtraining.functional",
            title: "좋았어요!",
            description: "허리를 곧게 유지하며 무릎 정렬이 안정적이었어요."
        ),
        PostureFeedback(
            imageName: "figure.cooldown",
            title: "개선하면 좋아요",
            description: "앉을 때 무릎이 안쪽으로 모이지 않게 주의해 주세요."
        ),
        PostureFeedback(
            imageName: "figure.mind.and.body",
            title: "다음엔 더 잘할 수 있어요!",
            description: "시선은 정면을 유지하면 더 더 안정적이에요."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Text("자세 분석 상세")
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("세트별 자세 분석")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                        VStack(spacing: 10) {
                            ForEach(setData) { set in
                                SetAnalysisRow(data: set, mintColor: mintColor)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("자세 피드백")
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
            
            Button(action: {}) {
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
    }
}

struct SetAnalysis: Identifiable {
    let id = UUID()
    let setNumber: Int
    let completed: Int
    let total: Int
    let accuracy: Int
}

struct SetAnalysisRow: View {
    let data: SetAnalysis
    let mintColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(data.setNumber)세트")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(mintColor)
                Spacer()
                Text("정확도 \(data.accuracy)%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 4) {
                Text("\(data.completed)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text("/ \(data.total)회")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(mintColor)
                        .frame(width: geometry.size.width * CGFloat(data.accuracy) / 100, height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }
}

struct PostureFeedback: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
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
                Text(data.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
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

#Preview {
    ExerciseAnalysisView()
}
