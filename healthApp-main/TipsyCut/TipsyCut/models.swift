//
//  models.swift
//  TipsyCut
//
//  Created by mac16 on 5/26/26.
//

//import Foundation

import SwiftUI

// MARK: - 운동 모델
struct Exercise: Identifiable, Hashable {
    
    let id = UUID()
    let name: String
    let category: String
    let imageName: String
}


// MARK: - 운동 데이터
extension Exercise {
    
    static let recommendedList: [Exercise] = [
        
        Exercise(
            name: "니푸쉬업",
            category: "상체",
            imageName: "knee_pushup"
        ),
        
        Exercise(
            name: "런지",
            category: "하체",
            imageName: "lunge"
        ),
        
        Exercise(
            name: "레그레이즈",
            category: "복근",
            imageName: "leg_raise"
        ),
        
        Exercise(
            name: "플랭크",
            category: "전신/코어",
            imageName: "plank"
        )
    ]
}


// MARK: - 운동 상세 정보 모델
struct ExerciseDetail {
    
    let videoID: String
    let description: String
    let tips: [String]
}


// MARK: - 운동 상세 정보 데이터
extension ExerciseDetail {
    
    /// 운동 이름으로 상세 정보 조회
    static let allDetails: [String: ExerciseDetail] = [
        
        "니푸쉬업": ExerciseDetail(
            videoID: "0DVCSDO30HU",
            description: "무릎을 대고 수행하는 푸쉬업으로, 초보자도 쉽게 상체 근력을 키울 수 있어요.",
            tips: [
                "손은 어깨 너비보다 넓게",
                "몸통 일직선 유지하기",
                "팔꿈치 45도 각도로",
                "천천히 내려갔다 올라오기"
            ]
        ),
        
        "런지": ExerciseDetail(
            videoID: "CaT6kHxngJE",
            description: "하체 전체를 단련하는 운동으로, 균형 감각과 하체 근력을 동시에 키울 수 있어요.",
            tips: [
                "상체 곧게 세우기",
                "앞무릎이 발끝 넘지 않게",
                "뒷무릎은 바닥 닿기 직전까지",
                "보폭 크게 내딛기"
            ]
        ),
        
        "레그레이즈": ExerciseDetail(
            videoID: "06D2t5orpds",
            description: "누워서 다리를 들어올리는 동작으로, 하복부를 집중적으로 자극하는 운동이에요.",
            tips: [
                "허리 바닥에 붙이기",
                "다리 모아서 올리기",
                "반동 없이 천천히",
                "내릴 때 바닥 닿기 직전 멈추기"
            ]
        ),
        
        "플랭크": ExerciseDetail(
            videoID: "v54Jtmi2BwU",
            description: "전신 코어를 강화하는 정적 운동으로, 척추 안정성과 자세 교정에 탁월해요.",
            tips: [
                "머리부터 발끝까지 일직선",
                "엉덩이 올리거나 내리지 않기",
                "복부에 힘 주기",
                "정면 바라보기"
            ]
        )
    ]
}


// MARK: - 앱 공통 컬러
extension Color {
    
    static let mintColor = Color(
        red: 0.2,
        green: 0.8,
        blue: 0.7
    )
}
