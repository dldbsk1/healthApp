//
//  GoalSettingView.swift
//  TipsyCut
//
//  Created by mac16 on 6/30/26.
//

import SwiftUI

struct GoalSettingView: View {

    @State private var selectedGoals: Set<String> = []

    let mintColor = Color(red: 0.40, green: 0.82, blue: 0.73)
    let lightMint = Color(red: 0.75, green: 0.92, blue: 0.87)
    let selectedMint = Color(red: 0.90, green: 0.98, blue: 0.95)
    let subColor = Color(white: 0.45)

    // SF Symbols 아이콘 명칭 지정
    let goals: [(title: String, icon: String)] = [
        ("체중 감량", "flame.fill"),
        ("근육 증가", "figure.walk"),
        ("건강 유지", "heart.fill"),
        ("습관 만들기", "leaf.fill")
        // ("즐겁게 마시기", "wineglass.fill") // 주석 처리
    ]

    var body: some View {

        ScrollView {

            VStack(spacing: 28) {

                // 진행바
                VStack(spacing: 12) {

                    Text("목표 설정")
                        .font(.headline)

                    GeometryReader { geo in

                        ZStack(alignment: .leading) {

                            Capsule()
                                .fill(lightMint)
                                .frame(height: 6)

                            Capsule()
                                .fill(mintColor)
                                .frame(width: geo.size.width * 0.75, height: 6)

                        }

                    }
                    .frame(height: 6)

                }
                .padding(.top, 10)

                // 제목
                VStack(spacing: 6) {

                    Text("당신의 목표는 무엇인가요?")
                        .font(.title2)
                        .bold()

                    Text("복수 선택이 가능해요!")
                        .font(.subheadline)
                        .foregroundColor(subColor)

                }
                .padding(.top, 30)

                // 카드
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 15
                ) {

                    ForEach(goals, id: \.title) { goal in

                        Button {

                            if selectedGoals.contains(goal.title) {
                                selectedGoals.remove(goal.title)
                            } else {
                                selectedGoals.insert(goal.title)
                            }

                        } label: {

                            VStack(spacing: 12) {

                                Image(systemName: goal.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(mintColor)

                                Text(goal.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)

                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                selectedGoals.contains(goal.title)
                                ? selectedMint
                                : Color(.systemGray6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedGoals.contains(goal.title)
                                        ? mintColor
                                        : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .cornerRadius(16)

                        }

                    }

                }
                .padding(.bottom, -10)

                // 다음 버튼
                NavigationLink(destination: SignUpCompleteView()) {

                    Text("다음")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(mintColor)
                        .cornerRadius(10)

                }
                .padding(.top, 20)

            }
            .padding(.horizontal)

        }

    }

}

#Preview {
    NavigationStack {
        GoalSettingView()
    }
}
