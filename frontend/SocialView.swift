import SwiftUI

struct SocialView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    
    // 💡 백엔드 연동을 위한 상태 변수
    @State private var receivedPost: SocialPostDTO? = nil
    @State private var isUploading = false
    @State private var selectedReaction: String? = nil
    @State private var showAddConfirmationAlert = false
    
    // 임시 유저 ID (실제로는 로그인한 유저 ID를 사용하세요)
    let currentUserId = "6a2f8b0b4f0ac94bcd66c9d4"
    let reactions = ["❤️", "😍", "💪", "👏", "🔥"]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 상단 문구
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘도 수고했어요! 💪")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("오늘의 순간을 기록해보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // --- 1. 내 사진 박스 ---
                    HStack {
                        Spacer()
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable().scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("📷 오늘의 기록")
                                            .font(.caption).fontWeight(.medium).foregroundColor(.white)
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(Color.black.opacity(0.5)).clipShape(Capsule())
                                            .padding([.top, .trailing], 12)
                                    }
                                    Spacer()
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6))
                                    .frame(width: 300, height: 300)
                                    .overlay(
                                        Text("오늘 기록 완료시, 밤 9시에\n랜덤으로 다른 유저와 사진을 교환해요!")
                                            .font(.footnote).foregroundColor(.secondary)
                                            .multilineTextAlignment(.center).padding()
                                    )
                            }
                        }
                        .frame(width: 300, height: 300)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // 사진 등록하기 버튼 (서버 전송)
                    Button(action: {
                        if selectedImage != nil { return }
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView()
                            } else {
                                Image(systemName: "camera")
                                Text(selectedImage == nil ? "사진 등록하기" : "등록 완료!")
                            }
                        }
                        .foregroundColor(selectedImage == nil ? Color(red: 0.2, green: 0.7, blue: 0.5) : .white)
                        .frame(maxWidth: .infinity).padding()
                        .background(selectedImage == nil ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.12) : Color(red: 0.2, green: 0.7, blue: 0.5))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    .disabled(selectedImage != nil || isUploading)
                    
                    // --- 2. 받은 사진 섹션 (서버에서 가져온 데이터) ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("받은 사진").font(.headline).fontWeight(.bold).padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            ZStack {
                                if let post = receivedPost {
                                    // 밤 9시가 넘어 사진을 성공적으로 받아온 경우
                                    AsyncImage(url: URL(string: post.imageUrl)) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Color.gray.opacity(0.3)
                                        }
                                    }
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    // 9시 이전이라서 잠겨있는 경우
                                    RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5))
                                        .frame(width: 300, height: 300)
                                    VStack(spacing: 12) {
                                        Image(systemName: "lock.fill").font(.system(size: 44)).foregroundColor(.gray)
                                        Text("밤 9시에 공개돼요!").font(.subheadline).fontWeight(.medium).foregroundColor(.gray)
                                    }
                                }
                            }
                            .frame(width: 300, height: 300)
                            Spacer()
                        }
                        
                        // --- 3. 리액션 바 ---
                        HStack(spacing: 12) {
                            ForEach(reactions, id: \.self) { reaction in
                                Button(action: { selectedReaction = reaction }) {
                                    Text(reaction).font(.system(size: 28)).padding(10)
                                        .background(selectedReaction == reaction ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.15) : Color(.systemGray6))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(selectedReaction == reaction ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear, lineWidth: 2))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.horizontal)
                        
                        // 리액션 보내기 버튼
                        Button(action: {
                            showAddConfirmationAlert = true
                        }) {
                            Text("리액션 보내기")
                                .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                                .background(selectedReaction != nil && receivedPost != nil ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.gray)
                                .cornerRadius(14).padding(.horizontal)
                        }
                        .alert("리액션을 보내시겠습니까?", isPresented: $showAddConfirmationAlert) {
                            Button("취소", role: .cancel) { }
                            Button("확인", role: .none) {
                                if let post = receivedPost, let emoji = selectedReaction {
                                    Task { try? await NetworkManager.shared.sendReaction(postId: post.id, emoji: emoji) }
                                }
                            }
                        }
                        .disabled(selectedReaction == nil || receivedPost == nil)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // 캘린더 이동 플로팅 버튼
            NavigationLink(destination: SocialCalendarView()) {
                Image(systemName: "calendar")
                    .font(.system(size: 22)).foregroundColor(.white).frame(width: 56, height: 56)
                    .background(Color(red: 0.2, green: 0.7, blue: 0.5)).clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 20).padding(.bottom, 30)
        }
        .onAppear {
            // 화면 켜질 때 밤 9시가 지났는지 서버에 물어보기
            Task {
                if let post = try? await NetworkManager.shared.fetchReceivedPhoto(userId: currentUserId) {
                    self.receivedPost = post
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            // 카메라로 사진을 찍고 돌아왔을 때 서버로 자동 업로드
            if let image = newImage {
                isUploading = true
                Task {
                    _ = try? await NetworkManager.shared.uploadSocialPost(userId: currentUserId, image: image)
                    DispatchQueue.main.async { self.isUploading = false }
                }
            }
        }
    }
}
// MARK: - 실제 아이폰 카메라를 띄워주는 CameraView
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // 💡 이 부분이 바로 '실제 카메라'를 작동시키는 핵심입니다!
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
