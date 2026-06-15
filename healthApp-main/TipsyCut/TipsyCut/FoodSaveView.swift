import SwiftUI

struct FoodVerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
   
    @Binding var showCamera: Bool
    @Binding var path: NavigationPath
    
    let defaultName: String
    let defaultWeight: String

    @State private var foodName: String
    @State private var foodWeight: String
    

    init(showCamera: Binding<Bool>, path: Binding<NavigationPath>, foodName: String = "닭가슴살 샐러드", foodWeight: String = "250") {
        self._showCamera = showCamera
        self._path = path
        self.defaultName = foodName
        self.defaultWeight = foodWeight
        
        _foodName = State(initialValue: foodName)
        _foodWeight = State(initialValue: foodWeight)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 1. 상단 타이틀
            VStack(spacing: 8) {
                Text("음식 정보 확인")
                    .font(.title2.bold())
                Text("AI가 분석한 결과가 맞는지 확인해 주세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // 2. 상단 중심: 음식 사진
            Image("unnamed")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // 3. 중앙: AI 제공 정보 및 수정 영역
            VStack(spacing: 20) {
                HStack {
                    Text("인식된 음식")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(foodName)
                        .font(.title3.bold())
                }
                .padding(.horizontal, 10)
                
                Divider()
                
                // 중량(g) 수정 입력창
                HStack {
                    Text("추정 중량")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 수정을 위한 텍스트 필드
                    HStack(spacing: 5) {
                        TextField("250", text: $foodWeight)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("g")
                            .font(.title3.bold())
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(20)
            .background(Color.black.opacity(0.02))
            .background(Color.white)
            .cornerRadius(15)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 4. 하단 버튼 영역
            HStack(spacing: 15) {
                // 다시 찍기 버튼
                Button(action: {
                    print("다시 찍기 버튼 클릭됨")

                    dismiss()
                }) {
                    Text("다시 찍기")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // 저장하기 버튼
                Button(action: {
                    print("저장하기 버튼 클릭됨. 최종 중량: \(foodWeight)g")
                    // TODO: 서버나 데이터베이스 저장 로직 수행
                    

                    showCamera = false
                }) {
                    Text("저장하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

    }
}

#Preview {
    // 프리뷰 작동 에러 방지용 가상 constant 매핑
    FoodVerView(showCamera: .constant(true), path: .constant(NavigationPath()))
}

