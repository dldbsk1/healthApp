import SwiftUI

// 추천 메뉴/안주의 섭취량(인분)을 조절하는 슬라이더
// 0.25인분 단위로 0.25 ~ 3인분까지 조절합니다.
struct ServingSliderView: View {
    @Binding var servings: Double
    var tint: Color = Color.mintColor

    private var label: String {
        servings.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(servings))인분"
            : String(format: "%g인분", servings)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("섭취량")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(label)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(tint)
            }

            Slider(value: $servings, in: 0.25...3.0, step: 0.25)
                .tint(tint)

            HStack {
                Text("0.25인분").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("3인분").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
