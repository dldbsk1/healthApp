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
        // FoodMainView처럼 전체 화면 스크롤이 자연스럽게 이어지도록 ScrollView 적용
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) { // FoodMainView와 동일한 간격 격차 설정
                
                // --- 1. 상단 타이틀 웰컴 멘트 (FoodMainView 스타일로 왼쪽 정렬 및 폰트 크기 조정) ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘은 어떤 술이 끌리시나요? 🌱") // 감성 이모지 추가 가능
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
                            // 카드 내부 디자인을 FoodMainView의 컴포넌트 스타일로 변경
                            VStack(alignment: .leading) {
                                Text(drink)
                                    .font(.system(size: 18, weight: .bold)) // 살짝 더 또렷하게 조정
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    Text(emoji)
                                        .font(.system(size: 36)) // 이모지 크기 최적화
                                }
                            }
                            .padding(20) // 내부 패딩을 늘려 여유로운 느낌 제공
                            .frame(maxWidth: .infinity)
                            .frame(height: 120) // FoodMainView 카드 비율에 맞춰 높이 소폭 조정
                            .background(Color(.systemBackground))
                            .cornerRadius(18) // FoodMainView 스타일의 부드러운 라운딩
                            // FoodMainView 특유의 은은하고 고급스러운 그림자 효과 적용
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        // 전체 배경색을 흰색이 아닌 약간 회색빛이 도는 깔끔한 시스템 배경으로 지정
        .background(Color(.secondarySystemBackground))
    }
}

// 프리뷰
#Preview {
    NavigationStack {
        DrinkSelectionView()
    }
}
