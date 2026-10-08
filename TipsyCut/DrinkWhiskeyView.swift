//
//  DrinkWhiskeyView.swift
//  TipsyCut
//
//  DrinkHighballView 와 같은 방식: 공통 뷰(DrinkBottleView)에 문구와 종류(DrinkSpec)만 넘긴다.
//

import SwiftUI

struct DrinkWhiskeyView: View {
    var body: some View {
        DrinkBottleView(
            title: "위스키 한 잔 🥃",
            subtitle: "위스키의 깊은 풍미에는\n진한 초콜릿이나 견과류가 잘 어울려요!",
            loadingText: "위스키의 풍미를 살려줄 안주를 찾는 중...",
            variants: [.whiskey]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkWhiskeyView()
    }
}
