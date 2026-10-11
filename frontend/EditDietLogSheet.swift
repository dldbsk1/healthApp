import SwiftUI

// 기록된 식단 한 건을 수정하거나 삭제하는 시트
struct EditDietLogSheet: View {
    let log: DietLog
    var onChanged: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 색상 정의 (메인 민트 테마)
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    @State private var name: String
    @State private var mealType: String
    @State private var amountText: String
    @State private var calories: String
    @State private var carbs: String
    @State private var protein: String
    @State private var fat: String
    
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String? = nil
    
    init(log: DietLog, onChanged: @escaping () -> Void) {
        self.log = log
        self.onChanged = onChanged
        _name = State(initialValue: log.foodName)
        _mealType = State(initialValue: log.mealType)
        _amountText = State(initialValue: EditDietLogSheet.format(log.amount))
        _calories = State(initialValue: EditDietLogSheet.format(log.calories))
        _carbs = State(initialValue: EditDietLogSheet.format(log.carbs))
        _protein = State(initialValue: EditDietLogSheet.format(log.protein))
        _fat = State(initialValue: EditDietLogSheet.format(log.fat))
    }
    
    // 소수 첫째 자리까지, 불필요한 0은 제거 (예: 1.50 → 1.5, 250.0 → 250)
    private static func format(_ value: Double) -> String {
        var text = String(format: "%.1f", value)
        if text.hasSuffix(".0") { text.removeLast(2) }
        return text
    }
    
    private var unitLabel: String { log.unit ?? "g" }
    
    // 수량을 바꾸면 처음 기록의 비율로 칼로리·탄단지도 같이 다시 계산 (아래 칸에서 직접 고칠 수도 있음)
    private var amountBinding: Binding<String> {
        Binding(
            get: { amountText },
            set: { newValue in
                amountText = newValue
                let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                if let newAmount = Double(cleaned), newAmount > 0, log.amount > 0 {
                    let ratio = newAmount / log.amount
                    calories = EditDietLogSheet.format(log.calories * ratio)
                    carbs = EditDietLogSheet.format(log.carbs * ratio)
                    protein = EditDietLogSheet.format(log.protein * ratio)
                    fat = EditDietLogSheet.format(log.fat * ratio)
                }
            }
        )
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 14) {
                        row(title: "메뉴 이름", text: $name, unit: nil, numeric: false)
                        row(title: "수량", text: amountBinding, unit: unitLabel, numeric: true)
                        
                        Divider()
                        
                        row(title: "칼로리", text: $calories, unit: "kcal", numeric: true)
                        row(title: "탄수화물", text: $carbs, unit: "g", numeric: true)
                        row(title: "단백질", text: $protein, unit: "g", numeric: true)
                        row(title: "지방", text: $fat, unit: "g", numeric: true)
                        
                        Divider()
                        
                        HStack {
                            Text("식사 분류")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                            Picker("식사 분류", selection: $mealType) {
                                Text("아침").tag("아침")
                                Text("점심").tag("점심")
                                Text("저녁").tag("저녁")
                                Text("간식").tag("간식")
                                Text("야식").tag("야식")
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        Task { await save() }
                    }) {
                        Group {
                            if isSaving {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("수정 저장").font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? mintColor : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .disabled(!canSave)
                    
                    Button(action: { showDeleteConfirm = true }) {
                        Text("이 기록 삭제")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                    }
                    .disabled(isSaving)
                }
                .padding(24)
            }
            .background(Color(.secondarySystemBackground).ignoresSafeArea())
            .navigationTitle("기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    Task { await delete() }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("삭제한 기록은 되돌릴 수 없어요.")
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func row(title: String, text: Binding<String>, unit: String?, numeric: Bool) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 70, alignment: .leading)
            TextField(title, text: text)
                .keyboardType(numeric ? .decimalPad : .default)
                .multilineTextAlignment(numeric ? .trailing : .leading)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            if let unit = unit {
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 34, alignment: .leading)
            }
        }
    }
    
    // 빈 칸은 0, 숫자가 아니면 nil
    private func number(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if cleaned.isEmpty { return 0 }
        guard let value = Double(cleaned), value >= 0 else { return nil }
        return value
    }
    
    private func save() async {
        guard let amountValue = number(amountText),
              let caloriesValue = number(calories),
              let carbsValue = number(carbs),
              let proteinValue = number(protein),
              let fatValue = number(fat) else {
            errorMessage = "숫자는 0 이상으로 입력해 주세요."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        var updated = log
        updated.foodName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.mealType = mealType
        updated.amount = amountValue
        updated.calories = caloriesValue
        updated.carbs = carbsValue
        updated.protein = proteinValue
        updated.fat = fatValue
        
        do {
            try await NetworkManager.shared.updateDietLog(updated)
            isSaving = false
            onChanged()
            dismiss()
        } catch {
            print("식단 수정 에러: \(error)")
            isSaving = false
            errorMessage = "수정하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
    
    private func delete() async {
        guard let id = log._id else {
            errorMessage = "이 기록은 삭제할 수 없어요."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await NetworkManager.shared.deleteDietLog(id: id, userId: log.userId)
            isSaving = false
            onChanged()
            dismiss()
        } catch {
            print("식단 삭제 에러: \(error)")
            isSaving = false
            errorMessage = "삭제하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}
