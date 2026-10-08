//
//  DrinkSpec.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/7/26.
//

import SwiftUI

// 술 한 병 기준 정보
// 용량·칼로리·도수·1잔 크기는 제공받은 주류 칼로리 표를 기준으로 합니다.
struct DrinkSpec: Identifiable {
    let id: String
    let label: String          // 종류 선택 버튼에 보이는 이름
    let logName: String        // 식단 기록에 저장되는 이름
    let pairingKey: String     // 안주 추천 요청에 쓰는 이름 (백엔드 diet_menus의 pairedDrink 카테고리)
    let bottleCC: Double       // 1병(캔) 용량(cc)
    let bottleKcal: Double     // 1병(캔) 칼로리(kcal)
    var cupCC: Double? = nil   // 1잔(컵) 크기(cc) — 없으면 "약 ○잔" 표시 생략
    var cupName: String? = nil // "잔" 또는 "컵"
    var abv: Int? = nil        // 알코올 도수(%) — 없으면 표시 생략
    let glassColor: Color      // 빈 병(캔) 색
    let liquidColor: Color     // 채워지는 음료 색
    let style: BottleStyle     // 병(캔) 모양
    var containerName: String = "병"   // "병" 또는 "캔"
}

extension DrinkSpec {
    static let soju = DrinkSpec(
        id: "soju", label: "소주", logName: "소주", pairingKey: "소주",
        bottleCC: 360, bottleKcal: 630, cupCC: 50, cupName: "잔", abv: 25,
        glassColor: Color(red: 0.35, green: 0.65, blue: 0.45).opacity(0.30),
        liquidColor: Color(red: 0.62, green: 0.86, blue: 0.90),
        style: .soju
    )

    // 표의 맥주(500cc/병) 칼로리는 "24"로 되어 있어 오타로 보고 240으로 사용
    // (1컵 200cc = 95kcal 기준 → 500cc ≈ 238kcal)
    static let beer = DrinkSpec(
        id: "beer", label: "맥주", logName: "맥주", pairingKey: "맥주",
        bottleCC: 500, bottleKcal: 240, cupCC: 200, cupName: "컵", abv: 4,
        glassColor: Color(red: 0.55, green: 0.35, blue: 0.15).opacity(0.30),
        liquidColor: Color(red: 0.98, green: 0.75, blue: 0.20),
        style: .beer
    )

    static let makgeolli = DrinkSpec(
        id: "makgeolli", label: "막걸리", logName: "막걸리", pairingKey: "막걸리",
        bottleCC: 750, bottleKcal: 410, cupCC: 200, cupName: "컵", abv: 6,
        glassColor: Color.gray.opacity(0.20),
        liquidColor: Color(red: 0.96, green: 0.94, blue: 0.84),
        style: .makgeolli
    )

    static let redWine = DrinkSpec(
        id: "redWine", label: "적 와인", logName: "레드 와인", pairingKey: "레드 와인",
        bottleCC: 700, bottleKcal: 590, cupCC: 150, cupName: "잔", abv: 12,
        glassColor: Color(red: 0.25, green: 0.35, blue: 0.25).opacity(0.30),
        liquidColor: Color(red: 0.55, green: 0.08, blue: 0.18),
        style: .wine
    )

    static let whiteWine = DrinkSpec(
        id: "whiteWine", label: "백 와인", logName: "화이트 와인", pairingKey: "화이트 와인",
        bottleCC: 700, bottleKcal: 650, cupCC: 150, cupName: "잔", abv: 12,
        glassColor: Color(red: 0.45, green: 0.65, blue: 0.40).opacity(0.25),
        liquidColor: Color(red: 0.95, green: 0.88, blue: 0.50),
        style: .wine
    )

    // 표에는 "640/잔"으로 되어 있지만 1잔(150cc)=65kcal 기준 640cc ≈ 280kcal이라 1병(640cc)으로 사용
    static let champagne = DrinkSpec(
        id: "champagne", label: "샴페인", logName: "샴페인", pairingKey: "스파클링 와인",
        bottleCC: 640, bottleKcal: 280, cupCC: 150, cupName: "잔", abv: 6,
        glassColor: Color(red: 0.30, green: 0.45, blue: 0.30).opacity(0.30),
        liquidColor: Color(red: 0.97, green: 0.90, blue: 0.60),
        style: .wine
    )

    // 편의점 짐빔 레몬 하이볼 (350ml 캔, 130kcal)
    static let highball = DrinkSpec(
        id: "highball", label: "하이볼", logName: "짐빔 레몬 하이볼", pairingKey: "하이볼",
        bottleCC: 350, bottleKcal: 130,
        glassColor: Color(red: 0.95, green: 0.85, blue: 0.20).opacity(0.25),
        liquidColor: Color(red: 0.98, green: 0.88, blue: 0.35),
        style: .can,
        containerName: "캔"
    )

    static let whiskey = DrinkSpec(
        id: "whiskey", label: "위스키", logName: "위스키", pairingKey: "싱글 몰트 위스키",
        bottleCC: 360, bottleKcal: 1000, cupCC: 40, cupName: "잔", abv: 40,
        glassColor: Color.gray.opacity(0.22),
        liquidColor: Color(red: 0.80, green: 0.50, blue: 0.15),
        style: .whiskey
    )
}

// 1.00 → "1", 0.50 → "0.5", 1.25 → "1.25"
func formatBottleCount(_ value: Double) -> String {
    var text = String(format: "%.2f", value)
    while text.contains(".") && (text.hasSuffix("0") || text.hasSuffix(".")) {
        text.removeLast()
    }
    return text
}
