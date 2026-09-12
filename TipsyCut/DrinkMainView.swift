import SwiftUI

struct DrinkSelectionView: View {
    
    let drinks = [
        ("맥주", "🍺"),
        ("소주", "🧪"),
        ("와인", "🍷"),
        ("하이볼", "🥃"),
        ("막걸리", "🍶"),
        ("위스키", "🥃")
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 타이틀 웰컴 멘트 ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘은 어떤 술이 끌리시나요? 🌱")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("딱 맞는 안주를 추천해 드릴게요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("원하는 종류를 선택하면 상세 정보로 이동합니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // --- 2. 주류 선택 그리드 영역 ---
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(drinks, id: \.0) { drink, emoji in
                        NavigationLink {
                            if drink == "와인" {
                                DrinkWineView()
                            } else {
                                Text("\(drink) 상세 뷰 준비 중 👨‍💻")
                                    .navigationTitle(drink)
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(drink)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    Text(emoji)
                                        .font(.system(size: 36))
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color(.systemBackground))
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.secondarySystemBackground))
    }
}

#Preview {
    NavigationStack {
        DrinkSelectionView()
    }
}
