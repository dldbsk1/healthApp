import SwiftUI

struct HomeView: View {
    
    // 💡 1. 회원가입 화면에서 계산된 '진짜 권장 칼로리'를 받을 수 있도록 변수 추가
    var userRecommendedCalories: Int = 2000 // 기본값 (프리뷰용)
    var userGoal: String = "유지"             // 목표: "감량" / "유지" / "증량" (프로필에서 전달)
    var onTapMyPage: () -> Void = {}          // 우측 상단 마이페이지 아이콘 탭 시 호출 (프로필 화면 열기)
    
    // MARK: - 색상
    // 운동: 메인 민트 (단색 링)
    let mintColor = Color.mintColor
    
    // 식단: 피치 → 코랄 그라데이션 링
    let foodColor = Color(red: 0.96, green: 0.52, blue: 0.40)       // 식단 메인 (텍스트/범례용)
    let foodLight = Color(red: 1.00, green: 0.78, blue: 0.52)       // 링 시작 (밝은 쪽)
    
    // 탄·단·지 색상: 식단 탭의 추천 메뉴 바(FoodMainView)와 동일
    let carbColor = Color(red: 0.98, green: 0.85, blue: 0.60)        // 탄수화물
    let proteinColor = Color(red: 0.98, green: 0.50, blue: 0.55)     // 단백질
    let fatColor = Color(red: 1.00, green: 0.88, blue: 0.35)         // 지방
    
    // 식단 링이 차오르는 애니메이션용 표시 값 (0 → 실제 비율)
    @State private var shownDietRatio: CGFloat = 0
    
    // --- 1. 식단 및 운동 권장량/소비량 목표 변수 ---
    // 오늘 운동 소비한 총 칼로리 = 운동 탭(AI 세션 + 직접 추가 기록)에서 누적된 실제 값
    @ObservedObject private var exerciseStore = ExerciseResultStore.shared
    private var todayBurnedCalorie: Double { exerciseStore.todayBurnedCalories }
    @State private var targetBurnedCalorie: Double = 600.0      // 권장 운동 소비 칼로리 목표
    
    @State private var todayLogs: [DietLog] = []
    
    // --- 연산 프로퍼티: 오늘 먹은 총 영양성분 및 칼로리 계산 ---
    var totalEatenCalorie: Double { todayLogs.reduce(0) { $0 + $1.calories } }
    var totalCarb: Double { todayLogs.reduce(0) { $0 + $1.carbs } }
    var totalProtein: Double { todayLogs.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { todayLogs.reduce(0) { $0 + $1.fat } }
    
    // MARK: - 하루 탄·단·지 목표 (nutrition.swift의 MacroTarget)
    private var macroTarget: MacroTarget {
        MacroTarget(calories: userRecommendedCalories, goal: userGoal)
    }
    private var targetCarb: Double { macroTarget.carb }
    private var targetProtein: Double { macroTarget.protein }
    private var targetFat: Double { macroTarget.fat }
    
    private var macroCaption: String {
        "\(userGoal) 목표 기준 · \(macroTarget.caption)"
    }
    
    // 💡 2. 전달받은 칼로리를 도넛 차트 비율 계산에 사용
    var dietRatio: CGFloat {
        let target = Double(userRecommendedCalories)
        return target > 0 ? CGFloat(min(totalEatenCalorie / target, 1.0)) : 0
    }
    var exerciseRatio: CGFloat {
        targetBurnedCalorie > 0 ? CGFloat(min(todayBurnedCalorie / targetBurnedCalorie, 1.0)) : 0
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                // --- 1. 상단 타이틀 + 우측 마이페이지 아이콘 ---
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("오늘도 건강한 하루를 완성해요! 🌱")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 0)
                        
                        Button(action: onTapMyPage) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(mintColor)
                                .frame(width: 50, height: 50)   // 터치 영역 확보
                                .contentShape(Circle())
                        }
                        .accessibilityLabel("마이페이지")
                    }
                    
                    Text("식단 기록과 운동 자세 분석으로 균형 잡힌 일상을 만듭니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // --- 2. 정중앙 이중 도넛모양 차트 대형 카드 영역 ---
                VStack(spacing: 24) {
                    Text("오늘의 활동 요약")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 이중 도넛 차트 본체
                    ZStack {
                        // 바깥쪽 원: 식단 섭취 칼로리 (피치 → 코랄 그라데이션, 차오르는 애니메이션)
                        Circle()
                            .stroke(foodColor.opacity(0.14), lineWidth: 16)
                            .frame(width: 200, height: 200)
                        Circle()
                            .trim(from: 0, to: shownDietRatio)
                            .stroke(
                                LinearGradient(
                                    colors: [foodLight, foodColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            
                        // 안쪽 원: 운동 소비 칼로리 (메인 민트 단색)
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
                            Text("\(Int(totalEatenCalorie)) / \(userRecommendedCalories)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(foodColor)
                            Text("\(Int(todayBurnedCalorie)) / \(Int(targetBurnedCalorie))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(mintColor)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // 범례 정보 표시
                    HStack(spacing: 30) {
                        HStack(spacing: 6) {
                            Circle().fill(foodColor).frame(width: 10, height: 10)
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
                
                // --- 3. 하단 세부 영양성분 스탯 카드 ---
                VStack(alignment: .leading, spacing: 20) {
                    Text("📋 섭취 영양소 상세 현황")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    Text(macroCaption)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 18) {
                        DashboardNutritionBar(label: "탄수화물", value: totalCarb, target: targetCarb, color: carbColor)
                        DashboardNutritionBar(label: "단백질", value: totalProtein, target: targetProtein, color: proteinColor)
                        DashboardNutritionBar(label: "지방", value: totalFat, target: targetFat, color: fatColor)
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
        // 빈 상단 네비게이션 바가 차지하던 공간 제거
        .toolbar(.hidden, for: .navigationBar)
        // 식단 링 채우기 애니메이션: 화면에 들어올 때마다 0에서 차오름
        .onAppear {
            shownDietRatio = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 1.2)) {
                    shownDietRatio = dietRatio
                }
            }
        }
        .onChange(of: dietRatio) { newValue in
            withAnimation(.easeOut(duration: 0.8)) { shownDietRatio = newValue }
        }
        .onAppear {
            exerciseStore.refreshForToday() // 날짜가 바뀌었으면 0으로 초기화
            Task {
                // 💡 1. 기기에서 로그인된 유저 ID 가져오기
                let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
                
                // 💡 2. 오늘 날짜 구하기
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd"
                let todayString = formatter.string(from: Date())
                
                do {
                    // 💡 3. 동적 변수를 사용하여 오늘의 데이터 요청
                    let response = try await NetworkManager.shared.fetchDailyDiet(userId: currentUserId, date: todayString)
                    
                    await MainActor.run {
                        self.todayLogs = response.logs
                    }
                } catch {
                    print("홈 화면 데이터 불러오기 실패: \(error)")
                }
            }
        }
    }
}

// --- 보조 컴포넌트: 영양소 달성도 프로그래스 바 (식단) ---
struct DashboardNutritionBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    var ratio: CGFloat {
        target > 0 ? CGFloat(min(value / target, 1.0)) : 0
    }
    
    @State private var shownRatio: CGFloat = 0
    
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
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * shownRatio, height: 8)
                }
            }
            .frame(height: 8)
            .onAppear {
                shownRatio = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeOut(duration: 1.0)) { shownRatio = ratio }
                }
            }
            .onChange(of: ratio) { newValue in
                withAnimation(.easeOut(duration: 0.8)) { shownRatio = newValue }
            }
        }
    }
}

#Preview {
    HomeView(userRecommendedCalories: 1850) // 프리뷰 테스트용
}
