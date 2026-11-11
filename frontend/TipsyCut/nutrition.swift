import SwiftUI

struct NutritionBar: View {
    let label: String       // 탄수화물, 단백질 등
    let value: Double      // 실제 값 (g)
    let ratio: Double      // 채워질 비율 (0.0 ~ 1.0)
    let color: Color       // 막대 색상
    
    @State private var drawingWidth: Double = 0 // 애니메이션용

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 레이블 및 수치 표시
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(Int(value))g")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    // 💡 [추가] 슬라이더로 양을 바꿀 때 숫자도 부드럽게 바뀜
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.25), value: Int(value))
            }
            
            // 막대 배경 및 채우기
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 배경 (연한 회색)
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    // 실제 데이터만큼 채워지는 막대
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * drawingWidth, height: 12)
                        // 입체감을 위한 은은한 그림자
                        .shadow(color: color.opacity(0.3), radius: 3, x: 2, y: 2)
                }
            }
            .frame(height: 12)
        }
        .onAppear {
            // 화면이 나타날 때 비율만큼 슥 차오르는 효과
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                drawingWidth = ratio
            }
        }
        // 💡 [추가] 비율이 바뀌면(인분 슬라이더를 움직이면) 막대도 그 비율로 왔다갔다 움직임
        //    (이전에는 화면이 처음 나타날 때 한 번만 값을 정해서, 슬라이더를 움직여도 막대가 그대로였음)
        .onChange(of: ratio) { _, newRatio in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                drawingWidth = newRatio
            }
        }
    }
}
