import SwiftUI

struct SocialOneDayView: View {
    // 💡 서버에서 받아온 DTO 원본을 그대로 전달받습니다.
    let post: SocialPostDTO
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 날짜 파싱 후 출력
                Text(formatLongDate(post.targetDate))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                // 테이프 + 폴라로이드 카드
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        GeometryReader { geo in
                            ZStack(alignment: .bottomLeading) {
                                // 💡 S3 URL에서 이미지를 불러옴
                                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
                                }
                                .frame(width: geo.size.width, height: geo.size.width)
                                .clipped()
                                
                                LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
                                    .frame(width: geo.size.width, height: geo.size.width)
                            }
                            .frame(width: geo.size.width, height: geo.size.width)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.top, 12).padding(.horizontal, 12)
                        
                        HStack {
                            Text(formatShortDate(post.targetDate))
                                .font(.caption).foregroundColor(Color(.systemGray2))
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                    }
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    .rotationEffect(.degrees(-1.5))
                    .padding(.horizontal, 24).padding(.top, 16)
                    
                    RoundedRectangle(cornerRadius: 2).fill(Color.yellow.opacity(0.35)).frame(width: 60, height: 18)
                        .overlay(
                            HStack(spacing: 4) {
                                ForEach(0..<6) { _ in Rectangle().fill(Color.white.opacity(0.25)).frame(width: 2) }
                            }
                        )
                        .rotationEffect(.degrees(-1.5)).shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1).zIndex(1)
                }
                .padding(.bottom, 16)
                
                // 💡 서버에서 받아온 진짜 리액션 섹션!
                VStack(alignment: .leading, spacing: 12) {
                    Text("받은 리액션")
                        .font(.headline).fontWeight(.bold).padding(.horizontal)
                    
                    if post.reactions.isEmpty {
                        Text("아직 받은 리액션이 없습니다.")
                            .font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                    } else {
                        // 딕셔너리를 배열로 변환해서 출력
                        HStack(spacing: 10) {
                            ForEach(post.reactions.sorted(by: >), id: \.key) { key, value in
                                HStack(spacing: 6) {
                                    Text(key).font(.system(size: 22))
                                    Text("\(value)").font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color(.systemGray6)).clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("이 날의 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- 날짜 포맷 헬퍼 함수 ---
    func formatLongDate(_ dateString: String) -> String {
        let inFormatter = DateFormatter(); inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: dateString) else { return dateString }
        let outFormatter = DateFormatter(); outFormatter.locale = Locale(identifier: "ko_KR"); outFormatter.dateFormat = "yyyy년 M월 d일 (E)"
        return outFormatter.string(from: date)
    }
    
    func formatShortDate(_ dateString: String) -> String {
        let inFormatter = DateFormatter(); inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: dateString) else { return dateString }
        let outFormatter = DateFormatter(); outFormatter.locale = Locale(identifier: "ko_KR"); outFormatter.dateFormat = "M월 d일"
        return outFormatter.string(from: date)
    }
}
