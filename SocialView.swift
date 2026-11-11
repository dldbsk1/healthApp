
import SwiftUI

struct SocialView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var selectedReaction: String? = nil
    
    // 컴파일 에러 방지용 상태 변수
    @State private var showAddConfirmationAlert = false
    @Environment(\.dismiss) var dismissView
    
    let reactions = ["❤️", "😍", "💪", "👏", "🔥"]
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 상단 문구
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘도 수고했어요!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("오늘의 순간을 기록해보세요 📸")
                            .font(.subheadline)
                            .foregroundColor(.subColor) // Models 식별자 적용
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // 내 사진 박스 (1:1 크기 제한 및 중앙 정렬)
                    HStack {
                        Spacer()
                        
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // 오늘의 기록 배지
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("📷 오늘의 기록")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Capsule())
                                            .padding([.top, .trailing], 12)
                                    }
                                    Spacer()
                                }
                            } else {
                                // 사진이 없을 때 나오는 기본 회색 박스
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 300, height: 300)
                                    .overlay(
                                        Text("오늘 기록 완료시, 밤 9시에\n랜덤으로 다른 유저와 사진을 교환해요!")
                                            .font(.footnote)
                                            .foregroundColor(.subColor) // Models 식별자 적용
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    )
                            }
                        }
                        .frame(width: 300, height: 300)
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // 사진 등록하기 버튼 (Models 민트 색상 체계 적용)
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            if let assetImage = UIImage(named: "5") {
                                selectedImage = assetImage
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 16))
                            Text("사진 등록하기")
                                .font(.headline)
                        }
                        .foregroundColor(.mintColor) // Models 식별자 적용
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mintTint.opacity(0.3)) // Models 식별자 적용
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    
                    // 받은 사진 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("받은 사진")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            ZStack {
                                if selectedImage != nil, let assetImage3 = UIImage(named: "6") {
                                    Image(uiImage: assetImage3)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 300, height: 300)
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.subColor) // Models 식별자 적용
                                        
                                        Text("밤 9시에 공개돼요!")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.subColor) // Models 식별자 적용
                                    }
                                }
                            }
                            .frame(width: 300, height: 300)
                            Spacer()
                        }
                        
                        // 리액션 바
                        HStack(spacing: 12) {
                            ForEach(reactions, id: \.self) { reaction in
                                Button(action: {
                                    selectedReaction = reaction
                                }) {
                                    Text(reaction)
                                        .font(.system(size: 28))
                                        .padding(10)
                                        .background(
                                            selectedReaction == reaction
                                            ? Color.selectedMint // Models 식별자 적용
                                            : Color(.systemGray6)
                                        )
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedReaction == reaction
                                                    ? Color.mintColor // Models 식별자 적용
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        
                        // 리액션 보내기 버튼
                        Button(action: {
                            showAddConfirmationAlert = true
                        }) {
                            Text("리액션 보내기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedReaction != nil ? Color.mintColor : Color.subColor) // Models 식별자 적용
                                .cornerRadius(14)
                                .padding(.horizontal)
                        }
                        .alert("\(selectedReaction ?? "")을 보내시겠습니까?", isPresented: $showAddConfirmationAlert) {
                            Button("취소", role: .cancel) { }
                            Button("확인", role: .none) { }
                        } message: {
                            Text("상대방의 피드에 해당 리액션이 등록됩니다.")
                        }
                        .disabled(selectedReaction == nil)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // 플로팅 캘린더 버튼
            NavigationLink(destination: SocialCalendarView()) {
                Image(systemName: "calendar")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.mintColor) // Models 식별자 적용
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
    }
}

// MARK: - CameraView
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


#Preview {
    NavigationStack {
        SocialView()
    }
}
