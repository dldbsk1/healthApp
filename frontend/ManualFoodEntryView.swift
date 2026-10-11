import SwiftUI

// 카메라 인식 실패 → 직접 입력 화면으로 이동할 때 쓰는 경로 값
struct ManualFoodRoute: Hashable {}

// 지금 시각 기준 식사 분류 기본값
func currentMealTypeByTime() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 4..<10: return "아침"
    case 10..<15: return "점심"
    case 15..<17: return "간식"
    case 17..<21: return "저녁"
    default: return "야식"
    }
}

// MARK: - 내 메뉴 사진 저장소 (이 기기)
// 사진은 앱 내부(Documents/MyFoodPhotos)에만 저장하고 서버로는 보내지 않아요.
// 크기를 줄여 JPEG로 다시 저장하므로 촬영 위치 같은 메타데이터도 남지 않아요.
enum MyFoodPhotoStore {
    private static let cache = NSCache<NSString, UIImage>()
    
    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("MyFoodPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    // 저장에 성공하면 파일 이름을 돌려줌
    static func save(_ image: UIImage) -> String? {
        let resized = resize(image, maxSide: 800)
        guard let data = resized.jpegData(compressionQuality: 0.75) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        do {
            try data.write(to: directory.appendingPathComponent(fileName), options: .atomic)
            return fileName
        } catch {
            print("사진 저장 실패: \(error)")
            return nil
        }
    }
    
    static func load(fileName: String) -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) { return cached }
        let path = directory.appendingPathComponent(fileName).path
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: fileName as NSString)
        return image
    }
    
    static func delete(fileName: String?) {
        guard let fileName = fileName else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
        cache.removeObject(forKey: fileName as NSString)
    }
    
    private static func resize(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(1, maxSide / max(size.width, size.height))
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - "메뉴 이름 → 사진 파일" 목록 (계정별, 이 기기)
// 내 메뉴 자체(이름·칼로리·탄단지)는 서버에 저장되고, 사진만 이 기기에 남아요.
// 그래서 다른 기기에서는 같은 메뉴가 나와도 사진은 보이지 않아요.
enum MyFoodStore {
    private static var storageKey: String {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "guest"
        return "myFoodPhotos_\(userId)"
    }
    
    private static func index() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
    }
    
    // 같은 이름에 이미 사진이 있으면 새 사진으로 교체 (이전 사진 파일은 삭제)
    static func setPhoto(fileName: String, forName name: String) {
        var list = index()
        if let old = list[name], old != fileName {
            MyFoodPhotoStore.delete(fileName: old)
        }
        list[name] = fileName
        UserDefaults.standard.set(list, forKey: storageKey)
    }
    
    // 메뉴를 삭제할 때 사진 파일도 함께 삭제
    static func remove(name: String) {
        var list = index()
        MyFoodPhotoStore.delete(fileName: list[name])
        list.removeValue(forKey: name)
        UserDefaults.standard.set(list, forKey: storageKey)
    }
    
    // 같은 이름의 내 메뉴에 사진이 있으면 돌려줌
    static func photo(forName name: String) -> UIImage? {
        guard let fileName = index()[name] else { return nil }
        return MyFoodPhotoStore.load(fileName: fileName)
    }
}

// 음식 썸네일: 인터넷 사진 → 없으면 이 기기에 저장된 내 메뉴 사진(이름이 같을 때) → 없으면 회색 칸
struct FoodThumbnailView: View {
    let imageUrl: String?
    var fallbackName: String? = nil
    var size: CGFloat = 50
    var cornerRadius: CGFloat = 8
    
    private var localImage: UIImage? {
        guard (imageUrl ?? "").isEmpty, let name = fallbackName else { return nil }
        return MyFoodStore.photo(forName: name)
    }
    
    private var remoteURL: URL? {
        guard let text = imageUrl, !text.isEmpty else { return nil }
        return URL(string: text)
    }
    
    var body: some View {
        Group {
            if let image = localImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = remoteURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    // 사진이 없을 때(식약처 결과 등) 보여줄 기본 이미지
    // - Assets에 "food_placeholder"라는 이름의 이미지를 추가하면 그 이미지를 쓰고,
    //   없으면 포크·나이프 아이콘을 보여줘요. (SF Symbols에는 숟가락 단독 아이콘이 없어요)
    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let custom = UIImage(named: "food_placeholder") {
                Image(uiImage: custom)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
        }
    }
}

// MARK: - 직접 입력 화면
struct ManualFoodEntryView: View {
    var initialName: String = ""
    var photo: UIImage? = nil
    var onSaved: () -> Void
    
    // MARK: - 색상 정의 (메인 민트 테마)
    let mintColor = Color.mintColor
    let selectedMint = Color.selectedMint
    
    @State private var name: String
    @State private var calories = ""
    @State private var carbs = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var mealType: String = currentMealTypeByTime()
    @State private var saveToMyFoods = true
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showMenuSaveFailAlert = false   // 식단은 기록됐지만 "내 메뉴" 저장에 실패한 경우
    
    init(initialName: String = "", photo: UIImage? = nil, onSaved: @escaping () -> Void) {
        self.initialName = initialName
        self.photo = photo
        self.onSaved = onSaved
        _name = State(initialValue: initialName)
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("직접 입력")
                        .font(.title2.bold())
                    Text("메뉴 이름만 필수예요.\n칼로리와 영양소는 아는 것만 입력하세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                // 카메라에서 넘어온 경우 찍은 사진 표시
                if let photo = photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                VStack(spacing: 14) {
                    inputRow(title: "메뉴 이름", text: $name, placeholder: "예: 엄마표 된장찌개", unit: nil, numeric: false)
                    inputRow(title: "칼로리", text: $calories, placeholder: "비워둘 수 있어요", unit: "kcal", numeric: true)
                    inputRow(title: "탄수화물", text: $carbs, placeholder: "비워둘 수 있어요", unit: "g", numeric: true)
                    inputRow(title: "단백질", text: $protein, placeholder: "비워둘 수 있어요", unit: "g", numeric: true)
                    inputRow(title: "지방", text: $fat, placeholder: "비워둘 수 있어요", unit: "g", numeric: true)
                    
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
                    
                    Toggle(isOn: $saveToMyFoods) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("내 메뉴에 저장")
                                .font(.system(size: 15, weight: .bold))
                            Text(photo != nil
                                 ? "나만 볼 수 있어요. 다음엔 음식 검색에서 바로 추가할 수 있고, 찍은 사진은 이 기기에 함께 저장돼요."
                                 : "나만 볼 수 있어요. 다음엔 음식 검색에서 바로 추가할 수 있어요.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(mintColor)
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
                            Text("기록하기").font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? mintColor : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                }
                .disabled(!canSave)
            }
            .padding(24)
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("직접 입력")
        .navigationBarTitleDisplayMode(.inline)
        .alert("내 메뉴에는 저장하지 못했어요", isPresented: $showMenuSaveFailAlert) {
            Button("확인") { onSaved() }
        } message: {
            Text("식단 기록은 저장됐어요. 서버 연결이나 업데이트 상태를 확인한 뒤, 검색에 나오게 하려면 다시 입력해 주세요.")
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func inputRow(title: String, text: Binding<String>, placeholder: String, unit: String?, numeric: Bool) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: text)
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
    
    // 빈 칸은 nil, 숫자가 아니면 nil
    private func parse(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
    
    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        let cal = parse(calories)
        let c = parse(carbs)
        let p = parse(protein)
        let f = parse(fat)
        
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? "6a2f8b0b4f0ac94bcd66c9d4"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentTimeString = formatter.string(from: Date())
        
        // 입력하지 않은 값은 0으로 기록 (식단 기록은 숫자만 받음)
        let log = DietLog(
            userId: currentUserId,
            mealType: mealType,
            foodName: trimmedName,
            amount: 1.0,
            calories: cal ?? 0,
            carbs: c ?? 0,
            protein: p ?? 0,
            fat: f ?? 0,
            imageUrl: "",
            eatenAt: currentTimeString,
            unit: "인분"
        )
        
        do {
            try await NetworkManager.shared.saveDietLog(log: log)
            
            // 기록이 끝난 뒤 "내 메뉴"로도 저장 (실패해도 이미 기록된 식단에는 영향 없음)
            var menuSaveFailed = false
            if saveToMyFoods {
                let menu = UserMenuRequest(
                    userId: currentUserId,
                    foodName: trimmedName,
                    calories: cal,
                    carbs: c,
                    protein: p,
                    fat: f
                )
                do {
                    try await NetworkManager.shared.saveUserMenu(menu)
                    // 서버에 메뉴가 저장된 경우에만 사진도 이 기기에 저장
                    if let photo = photo, let fileName = MyFoodPhotoStore.save(photo) {
                        MyFoodStore.setPhoto(fileName: fileName, forName: trimmedName)
                    }
                } catch {
                    print("내 메뉴 저장 실패: \(error)")
                    menuSaveFailed = true
                }
            }
            
            isSaving = false
            if menuSaveFailed {
                showMenuSaveFailAlert = true   // 조용히 넘어가지 않고 알려줌 (확인을 누르면 화면이 닫힘)
            } else {
                onSaved()
            }
        } catch {
            print("직접 입력 저장 에러: \(error)")
            isSaving = false
            errorMessage = "저장에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}
