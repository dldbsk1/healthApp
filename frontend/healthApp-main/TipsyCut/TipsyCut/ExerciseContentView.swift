//
//  ExerciseContentView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//

import SwiftUI

struct ExerciseContentView: View {
    let exerciseName: String
    @Binding var path: NavigationPath  // ← 추가: 부모의 path를 받아옴
    
    // 앱 메인 컬러 (민트)
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if let detail = ExerciseDetail.allDetails[exerciseName] {
                        
                        // 유튜브 썸네일
                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(detail.videoID)/maxresdefault.jpg")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 4)
                        )
                        .onTapGesture {
                            if let url = URL(string: "https://www.youtube.com/watch?v=\(detail.videoID)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.top)
                        
                        // 운동 설명
                        Text(detail.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // 자세 가이드
                        VStack(alignment: .leading, spacing: 12) {
                            Text("자세 가이드")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            ForEach(detail.tips, id: \.self) { tip in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(mintColor)
                                        .font(.system(size: 20))
                                    
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            
            // 운동 하러 가기 버튼
            Button(action: {
                // path에 LiveDestination 추가하면 LiveView로 push됨
                path.append(LiveDestination(name: exerciseName))
            }) {
                Text("운동 하러 가기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(mintColor)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExerciseContentView(exerciseName: "니푸쉬업", path: .constant(NavigationPath()))
    }
}
