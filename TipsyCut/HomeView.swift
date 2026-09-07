
import SwiftUI

struct HomeView: View {
    
    // 주어지거나 정의된 색상 (ExerciseAnalysisView의 민트색 활용)
    let mintColor = Color(red: 0.2, green: 0.8, blue: 0.7)
    let orangeColor = Color.orange
    
    // --- 1. [변수 추가] 식단 및 운동 권장량/소비량 목표 변수 정의 ---
    @State private var targetCalorie: Double = 2000.0          // 권장 섭취 칼로리 목표
    @State private var todayBurnedCalorie: Double = 450.0       // 오늘 운동 소비한 총 칼로리
    @State private var targetBurnedCalorie: Double = 600.0      // 권장 운동 소비 칼로리 목표
    
    // 샘플 식단 기록 데이터 (DietLog 배열)
    @State private var todayLogs: [DietLog] = [
        DietLog(diet_log_id: 1, user_id: 1, meal_type: "아침", food_name: "사과 & 요거트", amount: "1접시", calorie: 180, protein: 4, carb: 28, fat: 3, image_url: nil, eaten_at: "08:30", created_at: ""),
        DietLog(diet_log_id: 2, user_id: 1, meal_type: "점심", food_name: "현미밥 & 고등어구이", amount: "1인분", calorie: 450, protein: 32, carb: 60, fat: 11, image_url: nil, eaten_at: "12:15", created_at: ""),
        DietLog(diet_log_id: 3, user_id: 1, meal_type: "저녁", food_name: "닭가슴살 샐러드", amount: "250g", calorie: 350, protein: 35, carb: 15, fat: 8, image_url: nil, eaten_at: "18:40", created_at: "")
    ]
    
    // --- 연산 프로퍼티: 오늘 먹은 총 영양성분 및 칼로리 계산 ---
    var totalEatenCalorie: Double {
        todayLogs.reduce(0) { $0 + $1.calorie }
    }
    var totalCarb: Double { todayLogs.reduce(0) { $0 + $1.carb } }
    var totalProtein: Double { todayLogs.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { todayLogs.reduce(0) { $0 + $1.fat } }
    
    // 도넛 차트용 달성 비율 (최대 1.0)
    var dietRatio: CGFloat { CGFloat(min(totalEatenCalorie / targetCalorie, 1.0)) }
    var exerciseRatio: CGFloat { CGFloat(min(todayBurnedCalorie / targetBurnedCalorie, 1.0)) }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 타이틀 웰컴 멘트 (FoodMainView 스타일) ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘도 건강한 하루를 완성해요! 🌱")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("식단 기록과 운동 자세 분석으로 균형 잡힌 일상을 만듭니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // --- 2. 정중앙 이중 도넛모양 차트 대형 카드 영역 ---
                VStack(spacing: 24) {
                    Text("오늘의 활동 요약")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 이중 도넛 차트 본체
                    ZStack {
                        // 바깥쪽 원: 식단 섭취 칼로리 (오렌지색)
                        Circle()
                            .stroke(Color.orange.opacity(0.15), lineWidth: 16)
                            .frame(width: 200, height: 200)
                        Circle()
                            .trim(from: 0, to: dietRatio)
                            .stroke(orangeColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            
                        
                        // 안쪽 원: 운동 소비 칼로리 (민트색)
                        Circle()
                            .stroke(mintColor.opacity(0.15), lineWidth: 16)
                            .frame(width: 156, height: 156)
                        Circle()
                            .trim(from: 0, to: exerciseRatio)
                            .stroke(mintColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 156, height: 156)
                            .rotationEffect(.degrees(-90))
                            
                        
                        // 차트 중심부 텍스트 정보
                        VStack(spacing: 4) {
                            Text("오늘의 균형")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(Int(totalEatenCalorie)) / \(Int(targetCalorie))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.orange)
                            Text("\(Int(todayBurnedCalorie)) / \(Int(targetBurnedCalorie))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(mintColor)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // 범례 정보 표시
                    HStack(spacing: 30) {
                        HStack(spacing: 6) {
                            Circle().fill(orangeColor).frame(width: 10, height: 10)
                            Text("식단 권장량 수치").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(mintColor).frame(width: 10, height: 10)
                            Text("운동 소비량 수치").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                
                // --- 3. 하단 세부 영양성분 스탯 카드 (식이섬유 제외, 탄단지 구성) ---
                VStack(alignment: .leading, spacing: 20) {
                    Text("📋 섭취 영양소 상세 현황")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    VStack(spacing: 18) {
                        // 가이드 비율 기준점 (탄수:150g, 단백:75g, 지방:50g 가정)
                        DashboardNutritionBar(label: "탄수화물", value: totalCarb, target: 150.0, color: .blue)
                        DashboardNutritionBar(label: "단백질", value: totalProtein, target: 75.0, color: .orange)
                        DashboardNutritionBar(label: "지방", value: totalFat, target: 50.0, color: .green)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.secondarySystemBackground))
    }
}

// --- 보조 컴포넌트: 영양소 달성도 프로그래스 바 ---
struct DashboardNutritionBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    var ratio: CGFloat {
        CGFloat(min(value / target, 1.0))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value))g / \(Int(target))g")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * ratio, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    HomeView()
}
