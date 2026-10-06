import SwiftUI

struct DrinkWhiskeyView: View {
    var body: some View {
        DrinkBottleView(
            title: "위스키 🥃",
            subtitle: "위스키의 풍미를 살려줄 안주를 추천해드려요!",
            loadingText: "위스키와 어울리는 안주를 찾는 중...",
            variants: [.whiskey]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkWhiskeyView()
    }
}
