import SwiftUI

struct DrinkBeerView: View {
    var body: some View {
        DrinkBottleView(
            title: "시원한 맥주 🍺",
            subtitle: "하루의 피로를 날려줄,\n칼로리 부담 없는 완벽한 안주를 찾았어요!",
            loadingText: "맥주와 찰떡궁합인 안주를 찾는 중...",
            variants: [.beer]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkBeerView()
    }
}
