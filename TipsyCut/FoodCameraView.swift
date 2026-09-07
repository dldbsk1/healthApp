import SwiftUI

struct CameraContainerView: View {
    // 💡 [추가] 취소 버튼을 눌렀을 때 메인 화면(Food1)의 모달 시트를 닫기 위한 변수
    @Binding var showCamera: Bool
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                Text("📸 [카메라 촬영 화면 가상 레이아웃]")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                
                // 촬영 버튼
                NavigationLink(value: "verification") {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(Color.blue, lineWidth: 5))
                        .shadow(radius: 5)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("식단 촬영")
            .navigationBarTitleDisplayMode(.inline)
            // ✨ [새로 추가] 상단 내비게이션 바에 취소 버튼을 배치합니다.
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        // 💡 이 취소 버튼은 첫 진입점(모달) 자체를 닫는 것이므로
                        // 메인 화면에서 넘겨받은 시트 스위치를 꺼버리면 됩니다!
                        showCamera = false
                    }
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "verification" {
                    FoodVerView(showCamera: $showCamera, path: $path)
                }
            }
        }
    }
}

#Preview {
    CameraContainerView(showCamera: .constant(true))
}
