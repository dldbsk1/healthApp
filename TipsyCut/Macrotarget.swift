//
//  Macrotarget.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/12/26.
//

import Foundation

// 하루 권장 칼로리와 목표(감량/유지/증량)로 탄수화물·단백질·지방 목표(g)를 계산
struct MacroTarget {
    let carb: Double      // g
    let protein: Double   // g
    let fat: Double       // g
    let caption: String   // 예: "탄수화물 50% · 단백질 30% · 지방 20%"

    init(calories: Int, goal: String) {
        // 탄수화물 : 단백질 : 지방 비율
        // 유지 5:3:2 / 감량 4:4:2 / 증량 5:2.5:2.5
        let ratio: (carb: Double, protein: Double, fat: Double)
        switch goal {
        case "감량": ratio = (0.40, 0.40, 0.20)
        case "증량": ratio = (0.50, 0.25, 0.25)
        default:     ratio = (0.50, 0.30, 0.20)
        }

        let kcal = Double(calories)
        // 탄수화물·단백질 4kcal/g, 지방 9kcal/g
        carb = (kcal * ratio.carb / 4.0).rounded()
        protein = (kcal * ratio.protein / 4.0).rounded()
        fat = (kcal * ratio.fat / 9.0).rounded()
        caption = "탄수화물 \(Int(ratio.carb * 100))% · 단백질 \(Int(ratio.protein * 100))% · 지방 \(Int(ratio.fat * 100))%"
    }
}
