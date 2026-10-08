//
//  DrinkWineView.swift
//  TipsyCut
//
//  DrinkHighballView 와 같은 방식: 공통 뷰(DrinkBottleView)에 문구와 종류(DrinkSpec)만 넘긴다.
//  종류가 3개라서 화면 안에 적/백/샴페인 선택 버튼이 자동으로 나타난다.
//

import SwiftUI

struct DrinkWineView: View {
    var body: some View {
        DrinkBottleView(
            title: "와인 한 잔 🍷",
            subtitle: "와인에는 치즈나 고기 요리처럼\n풍미를 살려주는 안주가 제격이죠!",
            loadingText: "와인과 찰떡궁합인 안주를 찾는 중...",
            variants: [.redWine, .whiteWine, .champagne]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkWineView()
    }
}
