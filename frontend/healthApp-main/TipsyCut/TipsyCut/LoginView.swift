import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // 💡 백엔드에서 받아올 진짜 칼로리를 임시 저장할 변수
    @State private var fetchedCalories: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // --- 1. 앱 로고 및 타이틀 영역 ---
                VStack(spacing: 12) {
                    Text("🍻")
                        .font(.system(size: 70))
                    
                    Text("TipsyDiet")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("애주가를 위한 완벽한 다이어트 코치")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // --- 2. 입력 필드 영역 ---
                VStack(spacing: 16) {
                    TextField("이메일", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    SecureField("비밀번호", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // --- 3. 로그인 버튼 영역 ---
                VStack(spacing: 16) {
                    Button(action: {
                        performLogin()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("로그인")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(12)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    NavigationLink(destination: SignUpProfileView()) {
                        Text("아직 계정이 없으신가요? 회원가입")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Text("※ 본 서비스는 주류 추천 기능을 포함하고 있어\n만 19세 이상만 이용 가능합니다.")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            // 💡 화면이 넘어갈 때 서버에서 받아온 진짜 칼로리(fetchedCalories)를 넘겨줍니다!
            .navigationDestination(isPresented: $isLoggedIn) {
                MainTabView(userRecommendedCalories: fetchedCalories)
            }
        }
    }
    
    // --- 로그인 통신 로직 ---
    private func performLogin() {
        isLoading = true
        errorMessage = nil
        
        let loginData = UserLoginData(email: email, password: password)
        
        Task {
            do {
                // 💡 성공하면 진짜 칼로리 숫자가 calories에 담깁니다.
                if let calories = try await NetworkManager.shared.loginUser(loginData: loginData) {
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(self.email, forKey: "userId")
                        self.isLoading = false
                        self.fetchedCalories = calories // 받아온 칼로리 저장
                        self.isLoggedIn = true          // 화면 넘기기!
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "이메일 또는 비밀번호가 일치하지 않습니다."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "서버 연결에 실패했습니다."
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
