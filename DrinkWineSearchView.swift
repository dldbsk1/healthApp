import SwiftUI

struct WineSearchResult {
    let name: String
    let origin: String
    let price: String
    let imageUrl: String
    let pairings: [PairingFood]
}

struct PairingFood: Identifiable {
    let id = UUID()
    let name: String
    let imageUrl: String
}

struct DrinkWineSearchView: View {
    @State private var searchText = ""
    @State private var searchResult: WineSearchResult? = nil
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            
            // --- 🔍 1. 검색 바 영역 ---
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("와인 이름을 입력하세요...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                        .background(Color(.systemBackground))
                )
                
                Button(action: {
                    executeSearch()
                }) {
                    Text("검색")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(searchText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(searchText.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            Divider()
            
            // --- 🍷 2. 결과 표시 영역 ---
            if let wine = searchResult {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // [A] 와인 정보 카드
                        VStack(spacing: 16) {
                            Image(wine.imageUrl)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 220)
                                .padding(.top, 10)
                            
                            VStack(spacing: 8) {
                                Text(wine.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .multilineTextAlignment(.center)
                                
                                VStack(spacing: 8) {
                                    Text("📍 원산지: \(wine.origin)")
                                    Text("💵 가격: \(wine.price)")
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // [B] 페어링 추천 음식 섹션
                        VStack(alignment: .leading, spacing: 14) {
                            Text("💡 이 와인과 잘 어울리는 추천 음식")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(wine.pairings) { food in
                                        VStack(spacing: 8) {
                                            Image(food.imageUrl)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 130, height: 130)
                                                .cornerRadius(12)
                                                .clipped()
                                            
                                            Text(food.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: hasSearched ? "exclamationmark.magnifyingglass" : "wineglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(hasSearched ? "검색 결과가 없습니다.\n다른 와인 이름을 입력해 보세요." : "와인 이름을 검색하시면\n상세 정보와 추천 음식을 제공합니다.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
        .navigationTitle("와인 검색")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func executeSearch() {
        hasSearched = true
        
        if searchText.contains("레드") || searchText.lowercased().contains("red") {
            searchResult = WineSearchResult(
                name: "레드 와인 (카베르네 소비뇽)",
                origin: "프랑스 보르도",
                price: "45,000원",
                imageUrl: "wine1",
                pairings: [
                    PairingFood(name: "소고기 스테이크", imageUrl: "food1"),
                    PairingFood(name: "그릴드 소시지", imageUrl: "food2"),
                    PairingFood(name: "하드 치즈", imageUrl: "food3")
                ]
            )
        } else {
            searchResult = WineSearchResult(
                name: "화이트 와인 (샤르도네)",
                origin: "미국 캘리포니아",
                price: "32,000원",
                imageUrl: "wine2",
                pairings: [
                    PairingFood(name: "연어 스테이크", imageUrl: "food2"),
                    PairingFood(name: "봉골레 파스타", imageUrl: "food1"),
                    PairingFood(name: "리코타 샐러드", imageUrl: "food3")
                ]
            )
        }
    }
}

#Preview {
    NavigationStack {
        DrinkWineSearchView()
    }
}
