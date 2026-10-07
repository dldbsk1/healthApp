import SwiftUI

//발표용
struct SocialPost: Identifiable {
    let id = UUID()
    let dateString: String // "yyyy-MM-dd" 형식
    let imageName: String  // Assets에 등록된 이미지 이름
}

struct SocialCalendarView: View {
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var goToDetail = false
    
    
    
    // SocialView에서 넘겨받은 사진
    //let photosByDate: [String: UIImage]
    
    //발표용
    @State private var posts: [SocialPost] = [
            SocialPost(dateString: "2026-06-03", imageName: "1"),
            SocialPost(dateString: "2026-06-05", imageName: "2"),
            SocialPost(dateString: "2026-06-06", imageName: "3"),
            SocialPost(dateString: "2026-06-10", imageName: "4"),
            SocialPost(dateString: "2026-06-12", imageName: "5")
        ]
    let calendar = Calendar.current
    
    //발표용
    private var photosByDate: [String: UIImage] {
            var dict = [String: UIImage]()
            for post in posts {
                if let image = UIImage(named: post.imageName) {
                    dict[post.dateString] = image
                }
            }
            return dict
        }
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 월 네비게이션
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(day == "일" ? .red : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            Divider()
            
            // 날짜 그리드
            let days = generateDays(for: currentMonth)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let dateKey = dateToString(date)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
                        let hasPhoto = photosByDate[dateKey] != nil
                        
                        
                        Button(action: {
                            if hasPhoto {
                                selectedDate = date
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    goToDetail = true
                                }
                            }
                        }) {
                            
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(isToday ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear)
                                        .frame(width: 28, height: 28) // 오늘 표시 서클 크기 살짝 조절
                                    
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.subheadline)
                                        .foregroundColor(isToday ? .white : .primary)
                                }
                                
                                // [수정] 사진이 있다면 날짜 밑에 사진을 보여줍니다.
                                if let photo = photosByDate[dateKey] {
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36) // 날짜 공간 확보를 위해 크기 살짝 최적화
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear, lineWidth: 2)
                                        )
                                } else {
                                    // 사진이 없는 날에는 공간만 차지하도록 투명한 박스를 넣어 그리드 높이를 맞춥니다.
                                    Color.clear
                                        .frame(width: 36, height: 36)
                                }
                                
                                // 기존 점 표시 (유지 혹은 생략 가능)
                                Circle()
                                    .fill(hasPhoto ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                            // 사진과 숫자가 모두 들어가므로 버튼 전체의 frame 높이를 늘려줍니다.
                            .frame(minHeight: 75)
                        }
                        
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            // 안내 문구
            Text("사진이 있는 날짜를 눌러보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            Spacer()
        }
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToDetail) {
            if let selected = selectedDate,
               let photo = photosByDate[dateToString(selected)] {
                SocialOneDayView(date: selected, photo: photo)
            }
        }
    }
    
    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func generateDays(for month: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
}
/* 원래 코드
#Preview {
    // 오늘 날짜를 "yyyy-MM-dd" 형식의 문자열로 변환
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())
    
    // Assets의 "unnamed" 이미지를 불러옴 (없을 경우를 대비해 닐 코알레싱 처리)
    let dummyPhoto = UIImage(named: "오운완") ?? UIImage()
    
    return NavigationStack {
        SocialCalendarView(photosByDate: [todayString: dummyPhoto])
    }
}*/

#Preview {
    // 내부에서 상수를 정의할 수 있도록 클로저 연산을 사용하거나,
    // NavigationStack 내부에 배치하여 return 없이 뷰만 남도록 수정합니다.
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    // 현재 월의 3일, 5일, 6일, 10일 날짜를 동적으로 생성
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: Date())
    let year = components.year ?? 2026
    let month = components.month ?? 6
    
    let date3 = calendar.date(from: DateComponents(year: year, month: month, day: 3)) ?? Date()
    let date5 = calendar.date(from: DateComponents(year: year, month: month, day: 5)) ?? Date()
    let date6 = calendar.date(from: DateComponents(year: year, month: month, day: 6)) ?? Date()
    let date10 = calendar.date(from: DateComponents(year: year, month: month, day: 10)) ?? Date()
    
    // 변환된 딕셔너리 더미 데이터
    let dummyPhotos: [String: UIImage] = [
        formatter.string(from: date3): UIImage(named: "1") ?? UIImage(),
        formatter.string(from: date5): UIImage(named: "2") ?? UIImage(),
        formatter.string(from: date6): UIImage(named: "3") ?? UIImage(),
        formatter.string(from: date10): UIImage(named: "4") ?? UIImage()
    ]
    
    NavigationStack {
        SocialCalendarView()
    }
}
