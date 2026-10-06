import SwiftUI

struct DrinkSojuView: View {
    var body: some View {
        DrinkBottleView(
            title: "캬~ 소주 한 잔 🍶",
            subtitle: "소주에는 역시 뜨끈한 국물이나\n매콤한 요리가 제격이죠! 이 안주 어때요?",
            loadingText: "소주와 찰떡궁합인 안주를 찾는 중...",
            variants: [.soju]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkSojuView()
    }
}
