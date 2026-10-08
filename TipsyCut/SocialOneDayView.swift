//
//  SocialOneDayView.swift
//  TipsyCut
//
//  ⚠️ photo: UIImage 를 직접 받던 방식에서, date 만 받아서 서버에서 상세를 조회하는 방식으로 변경.
//

import SwiftUI

struct SocialOneDayView: View {
    let date: Date

    @State private var detail: PhotoDetailResponse? = nil
    @State private var isLoading = true

    /// reactionType 별 개수 집계
    private var reactionCounts: [(type: PhotoReactionType, count: Int)] {
        guard let reactions = detail?.reactions else { return [] }
        var counts: [PhotoReactionType: Int] = [:]
        for r in reactions {
            counts[r.reactionType, default: 0] += 1
        }
        return PhotoReactionType.allCases.compactMap { type in
            guard let c = counts[type] else { return nil }
            return (type, c)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text(dateString(from: date))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if let detail = detail, let url = AppConfig.resolvedImageURL(detail.imageUrl) {

                    // 테이프 + 폴라로이드 카드
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            GeometryReader { geo in
                                ZStack(alignment: .bottomLeading) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color(.systemGray5)
                                    }
                                    .frame(width: geo.size.width, height: geo.size.width)
                                    .clipped()

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

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.yellow.opacity(0.35))
                            .frame(width: 60, height: 18)
                            .overlay(
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

                        if reactionCounts.isEmpty {
                            Text("아직 받은 리액션이 없어요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            HStack(spacing: 10) {
                                ForEach(reactionCounts, id: \.type) { item in
                                    HStack(spacing: 6) {
                                        Text(item.type.emoji)
                                            .font(.system(size: 22))
                                        Text("\(item.count)")
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
                    }
                    .padding(.bottom, 40)
                } else {
                    Text("이 날짜의 사진을 불러오지 못했어요")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("이 날의 기록")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchDetail() }
    }

    private func fetchDetail() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        PhotoAPIClient.shared.fetchDetail(dateString: dateString) { response in
            detail = response
            isLoading = false
        }
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
}

#Preview {
    NavigationStack {
        SocialOneDayView(date: Date())
    }
}
