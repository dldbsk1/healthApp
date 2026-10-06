import SwiftUI

struct DrinkWineView: View {
    var body: some View {
        DrinkBottleView(
            title: "와인 🍷",
            subtitle: "종류를 고르고 한 병 기준으로 얼마나 마셨는지 채워보세요.\n어울리는 안주를 추천해드려요!",
            loadingText: "와인과 어울리는 안주를 찾는 중...",
            variants: [.redWine, .whiteWine, .champagne]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkWineView()
    }
}
