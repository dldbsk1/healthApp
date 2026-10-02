//
//  models.swift
//  TipsyCut
//
//  Created by mac16 on 5/26/26.
//

//import Foundation

import SwiftUI

// MARK: - 앱 공통 컬러 시스템
extension Color {
    
    // 1. 메인 민트 
    static let mintColor = Color(
        red: 0.40,
        green: 0.82,
        blue: 0.73
    )
    
    // 2. 밝은 민트 (카드 배경, 보조 요소용)
    static let lightMint = Color(
        red: 0.75,
        green: 0.92,
        blue: 0.87
    )
    
    // 3. 서브 컬러 (진한 회색조 텍스트, 비활성화 요소용)
    static let subColor = Color(
        white: 0.45
    )
    
    // 4. 선택된 상태 민트 (선택된 카드, 연한 강조 배경용)
    static let selectedMint = Color(
        red: 0.90,
        green: 0.98,
        blue: 0.95
    )
    
    // 5. 민트 틴트 (버튼 틴트, 프로그레스 바 영역 등, 웰컴뷰에서 만듦)
    static let mintTint = Color(
        red: 0.70,
        green: 0.88,
        blue: 0.83
    )
    
    // 6. 식단 메인 전용 컬러 (식단과 대비되는 어두운 청록) 
    static let deepTeal = Color(
        red: 0.10,
        green: 0.45,
        blue: 0.45
    )
    
    // 7. 식단 하위 영양소 상징색 (밝고 산뜻한 파스텔 톤) 변경중
    static let carbColor = Color(red: 0.98, green: 0.85, blue: 0.60)      // 탄수화물 (더 또렷하고 따뜻한 베이지)
    static let proteinColor = Color(red: 0.98, green: 0.50, blue: 0.55)   // 단백질 (밝고 선명해진 코랄 핑크)
    static let fatColor = Color(red: 1.00, green: 0.88, blue: 0.35)       // 지방 (밝고 선명한 소프트 옐로우)
}

// MARK: - 앱 이동 경로 Enum
enum AppRoute: Hashable {
    case login
    case signUpBasic       // 회원가입: 기본 정보 입력
    case userInfo1          // 사용자 정보 입력 1/2
    case userInfo2          // 사용자 정보 입력 2/2
    case goalSetting       // 목표 설정
    case signUpComplete    // 가입 완료!
    case mainHome          // 메인 뷰
}

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
        Exercise(name: "니푸쉬업", category: "상체", imageName: "knee_pushup"),
        Exercise(name: "런지", category: "하체", imageName: "lunge"),
        Exercise(name: "레그레이즈", category: "복근", imageName: "leg_raise"),
        Exercise(name: "플랭크", category: "전신/코어", imageName: "plank")
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
