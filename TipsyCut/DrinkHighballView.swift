//
//  DrinkHighballView.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/7/26.
//

import SwiftUI

struct DrinkHighballView: View {
    var body: some View {
        DrinkBottleView(
            title: "청량한 하이볼 🍹",
            subtitle: "톡 쏘는 상큼한 하이볼에는\n가벼운 핑거푸드나 짭짤한 꼬치구이가 딱이죠!",
            loadingText: "하이볼의 청량함을 살려줄 안주를 찾는 중...",
            variants: [.highball]
        )
    }
}

#Preview {
    NavigationStack {
        DrinkHighballView()
    }
}
