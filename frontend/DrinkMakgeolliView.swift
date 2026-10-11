import SwiftUI

struct DrinkMakgeolliView: View {
    var body: some View {
        DrinkBottleView(
            title: "구수한 막걸리 🫖",
            subtitle: "막걸리에는 역시 바삭한 부침개나\n고소한 두부, 매콤한 무침 요리가 최고죠!",
            loadingText: "막걸리와 찰떡궁합인 안주를 찾는 중...",
            variants: [.makgeolli]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkMakgeolliView()
    }
}
