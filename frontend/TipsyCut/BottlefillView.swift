//
//  BottlefillView.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/7/26.
//

import SwiftUI

// 병 모양 종류
enum BottleStyle {
    case soju, beer, makgeolli, wine, whiskey, can

    // 병 너비 대비 목 너비
    var neckWidthRatio: CGFloat {
        switch self {
        case .soju: return 0.36
        case .beer: return 0.30
        case .makgeolli: return 0.46
        case .wine: return 0.24
        case .whiskey: return 0.40
        case .can: return 1.0
        }
    }

    // 병 높이 대비 목 길이
    var neckHeightRatio: CGFloat {
        switch self {
        case .soju: return 0.28
        case .beer: return 0.34
        case .makgeolli: return 0.16
        case .wine: return 0.36
        case .whiskey: return 0.14
        case .can: return 0.0
        }
    }

    // 병 높이 대비 어깨(목 → 몸통으로 넓어지는 구간) 길이
    var shoulderHeightRatio: CGFloat {
        switch self {
        case .soju: return 0.14
        case .beer: return 0.16
        case .makgeolli: return 0.12
        case .wine: return 0.15
        case .whiskey: return 0.12
        case .can: return 0.0
        }
    }

    // 화면에 그려지는 높이 (캔은 병보다 낮게)
    var displayHeight: CGFloat {
        switch self {
        case .can: return 160
        default: return 230
        }
    }
}

// 병 외곽선
struct BottleShape: Shape {
    let style: BottleStyle

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        
        // 캔: 위아래 가장자리가 살짝 좁아지는 원통형
        if style == .can {
            let inset = w * 0.07
            let lip = h * 0.05
            let slope = h * 0.025
            var c = Path()
            c.move(to: CGPoint(x: inset, y: 0))
            c.addLine(to: CGPoint(x: w - inset, y: 0))
            c.addLine(to: CGPoint(x: w - inset, y: lip))
            c.addLine(to: CGPoint(x: w, y: lip + slope))
            c.addLine(to: CGPoint(x: w, y: h - lip - slope))
            c.addLine(to: CGPoint(x: w - inset, y: h - lip))
            c.addLine(to: CGPoint(x: w - inset, y: h))
            c.addLine(to: CGPoint(x: inset, y: h))
            c.addLine(to: CGPoint(x: inset, y: h - lip))
            c.addLine(to: CGPoint(x: 0, y: h - lip - slope))
            c.addLine(to: CGPoint(x: 0, y: lip + slope))
            c.addLine(to: CGPoint(x: inset, y: lip))
            c.closeSubpath()
            return c
        }
        
        let cx = rect.midX
        let neckHalf = w * style.neckWidthRatio / 2
        let neckH = h * style.neckHeightRatio
        let shoulderH = h * style.shoulderHeightRatio
        let bodyTop = neckH + shoulderH
        let r = min(w * 0.18, 14)

        var p = Path()
        p.move(to: CGPoint(x: cx - neckHalf, y: 0))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: 0))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: neckH))
        p.addCurve(
            to: CGPoint(x: w, y: bodyTop),
            control1: CGPoint(x: cx + neckHalf, y: neckH + shoulderH * 0.7),
            control2: CGPoint(x: w, y: bodyTop - shoulderH * 0.6)
        )
        p.addLine(to: CGPoint(x: w, y: h - r))
        p.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: r, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - r), control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: bodyTop))
        p.addCurve(
            to: CGPoint(x: cx - neckHalf, y: neckH),
            control1: CGPoint(x: 0, y: bodyTop - shoulderH * 0.6),
            control2: CGPoint(x: cx - neckHalf, y: neckH + shoulderH * 0.7)
        )
        p.closeSubpath()
        return p
    }
}

// 세로로 드래그해서 병 속 음료를 채우는 뷰 (fraction: 0 ~ 1, 한 병 기준으로 마신 비율)
struct BottleFillView: View {
    @Binding var fraction: Double
    let style: BottleStyle
    let glassColor: Color
    let liquidColor: Color
    var step: Double = 0.05

    private let bottleWidth: CGFloat = 80
    private let markValues: [Double] = [0.25, 0.5, 0.75, 1.0]
    private let markLabels: [String] = ["¼", "½", "¾", "가득"]

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            // 병이 "가득"인 위치 — 실제 병처럼 입구 끝이 아니라 목 중간까지 채워진 모습으로 표현
            let fullHeight = height * (1 - style.neckHeightRatio * 0.6)

            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottom) {
                    BottleShape(style: style)
                        .fill(glassColor)

                    ZStack(alignment: .bottom) {
                        Color.clear
                        Rectangle()
                            .fill(liquidColor)
                            .frame(height: fullHeight * CGFloat(fraction))
                    }
                    .mask(BottleShape(style: style))

                    BottleShape(style: style)
                        .stroke(Color.gray.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                }
                .frame(width: bottleWidth, height: height)
                .animation(.easeOut(duration: 0.12), value: fraction)

                // 눈금
                ForEach(0..<markValues.count, id: \.self) { i in
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 8, height: 1)
                        Text(markLabels[i])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .offset(x: bottleWidth + 6, y: height - fullHeight * CGFloat(markValues[i]) - 7)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let raw = Double((height - value.location.y) / fullHeight)
                        let clamped = min(max(raw, 0), 1)
                        fraction = (clamped / step).rounded() * step
                    }
            )
        }
    }
}
