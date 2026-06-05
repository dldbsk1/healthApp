//
//  SocialCalendarView.swift
//  TipsyCut
//
//  Created by mac16 on 5/19/26.
//

import SwiftUI

struct SocialCalendarView: View {
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var goToDetail = false
    
    // SocialView에서 넘겨받은 사진
    let photosByDate: [String: UIImage]
    
    let calendar = Calendar.current
    
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
                            VStack(spacing: 2) {
                                if let photo = photosByDate[dateKey] {
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear, lineWidth: 2)
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(isToday ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear)
                                            .frame(width: 32, height: 32)
                                        
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.subheadline)
                                            .foregroundColor(isToday ? .white : .primary)
                                    }
                                    .frame(width: 44, height: 44)
                                }
                                
                                Circle()
                                    .fill(hasPhoto ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
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

#Preview {
    NavigationStack {
        SocialCalendarView(photosByDate: [:])
    }
}
