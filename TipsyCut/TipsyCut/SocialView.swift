//
//  SocialView.swift
//  TipsyCut
//
//  Created by mac16 on 5/19/26.
//

import SwiftUI

struct SocialView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var selectedReaction: String? = nil
    
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
                    
                    // 내 사진 박스 (1:1)
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("📷 오늘의 기록")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Capsule())
                                        .padding(.top, 20)
                                        .padding(.trailing, 28)
                                }
                                Spacer()
                            }
                            
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .aspectRatio(1, contentMode: .fit)
                                .padding(.horizontal)
                                .overlay(
                                    Text("오늘 기록 완료시, 밤 9시에\n랜덤으로 다른 유저와 사진을 교환해요!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                )
                        }
                    }
                    
                    // 사진 등록하기 버튼
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 16))
                            Text("사진 등록하기")
                                .font(.headline)
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.5))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.12))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    
                    // 받은 사진 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("받은 사진")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // 받은 사진 박스 (1:1)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                                .aspectRatio(1, contentMode: .fit)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray)
                                
                                Text("밤 9시에 공개돼요!")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
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
                                            ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.15)
                                            : Color(.systemGray6)
                                        )
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedReaction == reaction
                                                    ? Color(red: 0.2, green: 0.7, blue: 0.5)
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
                        Button(action: {}) {
                            Text("리액션 보내기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedReaction != nil ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.gray)
                                .cornerRadius(14)
                                .padding(.horizontal)
                        }
                        .disabled(selectedReaction == nil)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // 플로팅 버튼
            NavigationLink(destination: SocialCalendarView(photosByDate: selectedImage != nil ? [dateToString(Date()): selectedImage!] : [:])) {
                Image(systemName: "calendar")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color(red: 0.2, green: 0.7, blue: 0.5))
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
