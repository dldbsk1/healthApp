//
//  ExerciseLiveView.swift
//  TipsyCut
//
//  Created by mac16 on 5/17/26.
//

import SwiftUI

struct ExerciseLiveView: View {
    
    let exerciseName: String
    @Binding var path: NavigationPath
    
    // 운동 완료 화면 이동 상태
    @State private var goToEndView = false
    
    // 앱 메인 컬러 (민트)
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            Spacer()
            
            Text(exerciseName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            
            // 운동 완료 버튼
            Button(action: {
                goToEndView = true
            }) {
                Text("운동 완료")
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
        
        
        // ExerciseEndView 이동
        .navigationDestination(isPresented: $goToEndView) {
            
            ExerciseEndView(
                path: $path
            )
        }
        
        
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExerciseLiveView(
            exerciseName: "니푸쉬업",
            path: .constant(NavigationPath())
        )
    }
}
