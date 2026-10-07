//
//  SocialOneDayView.swift
//  TipsyCut
//
//  Created by mac16 on 5/19/26.
//

import SwiftUI

struct SocialOneDayView: View {
    let date: Date
    let photo: UIImage
    
    let reactions: [(emoji: String, count: Int)] = [
        ("❤️", 3),
        ("😍", 1),
        ("💪", 2),
        ("👏", 4),
        ("🔥", 1)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 날짜
                Text(dateString(from: date))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                // 테이프 + 폴라로이드 카드
                ZStack(alignment: .top) {
                    
                    // 폴라로이드 카드
                    VStack(spacing: 0) {
                        
                        // 상단 + 좌우 여백
                        GeometryReader { geo in
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.width)
                                    .clipped()
                                
                                // 하단 그라디언트
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.35)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                .frame(width: geo.size.width, height: geo.size.width)
                            }
                            .frame(width: geo.size.width, height: geo.size.width)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                        
                        // 하단 흰 여백 + 날짜
                        HStack {
                            Text(shortDateString(from: date))
                                .font(.caption)
                                .foregroundColor(Color(.systemGray2))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    .rotationEffect(.degrees(-1.5))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // 테이프 (상단 중앙)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellow.opacity(0.35))
                        .frame(width: 60, height: 18)
                        .overlay(
                            // 테이프 줄무늬 느낌
                            HStack(spacing: 4) {
                                ForEach(0..<6) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(width: 2)
                                }
                            }
                        )
                        .rotationEffect(.degrees(-1.5))
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .zIndex(1)
                }
                .padding(.bottom, 16)
                
                // 리액션 섹션
                VStack(alignment: .leading, spacing: 12) {
                    Text("받은 리액션")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        ForEach(reactions, id: \.emoji) { reaction in
                            HStack(spacing: 6) {
                                Text(reaction.emoji)
                                    .font(.system(size: 22))
                                Text("\(reaction.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("이 날의 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }
    
    func shortDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SocialOneDayView(
            date: Date(),
            photo: UIImage()
        )
    }
}
