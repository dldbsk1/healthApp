import SwiftUI
import Combine

final class SocialViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var uploadedPhotoURL: String? = nil
    @Published var receivedPhoto: ReceivedPhotoResponse? = nil

    /// 내가 올린 오늘 사진에 상대가 보낸 리액션 (내 사진 오른쪽 아래에 표시)
    @Published var myPhotoReactions: [PhotoReactionResponse] = []
    @Published var isUploading = false
    @Published var uploadErrorMessage: String? = nil
    
    // 💡 이미 서버 데이터를 불러왔는지 확인하여 불필요한 재요청 방지
    private var hasFetchedMyTodayPhoto = false

    // 사진이 "오늘" 것인지 구분하기 위한 날짜 (날짜가 바뀌면 어제 사진은 비운다)
    private var photoDay = SocialViewModel.dayString()

    private static func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    init() {
        // 소통 탭에 들어오기 전에도 서버에 올려둔 오늘 사진을 미리 복원
        fetchMyTodayPhoto()
    }

    private func resetIfNewDay() {
        let today = SocialViewModel.dayString()
        if photoDay != today {
            photoDay = today
            selectedImage = nil
            uploadedPhotoURL = nil
            myPhotoReactions = []
            hasFetchedMyTodayPhoto = false
        }
    }

    /// 내 오늘 사진 + 그 사진에 달린 리액션을 서버에서 가져온다.
    /// - 리액션은 호출할 때마다 최신으로 갱신
    /// - 사진 URL 은 이미 있으면(방금 올렸거나 이미 복원했으면) 덮어쓰지 않아 탭을 오가도 유지된다
    func fetchMyTodayPhoto(forceRefresh: Bool = false) {
        resetIfNewDay()

        PhotoAPIClient.shared.fetchMyTodayPhoto { [weak self] detail in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.hasFetchedMyTodayPhoto = true

                guard let detail = detail else {
                    print("⚠️ [MyTodayPhoto Warning] 오늘 등록된 내 사진 없음")
                    return
                }

                print("✅ [MyTodayPhoto Success] 사진 유지 + 받은 리액션 \(detail.reactions.count)개")

                self.myPhotoReactions = detail.reactions

                if self.uploadedPhotoURL == nil || forceRefresh {
                    self.uploadedPhotoURL = detail.imageUrl
                }
            }
        }
    }

    func uploadPhoto(_ image: UIImage) {
        isUploading = true
        uploadErrorMessage = nil
        PhotoAPIClient.shared.upload(image: image) { [weak self] response in
            DispatchQueue.main.async {
                self?.isUploading = false
                if let response = response {
                    print("✅ [Upload Success] 업로드 완료 URL: \(response.imageUrl)")
                    self?.uploadedPhotoURL = response.imageUrl
                    self?.hasFetchedMyTodayPhoto = true

                    // 내 사진을 올린 직후에 받은 사진 상태가 달라질 수 있으므로 다시 조회
                    self?.refreshReceivedPhoto()
                } else {
                    self?.uploadErrorMessage = "사진 업로드에 실패했어요. 다시 시도해주세요."
                }
            }
        }
    }

    /// completion 은 서버 응답을 receivedPhoto 에 반영한 뒤 메인 스레드에서 호출된다.
    func refreshReceivedPhoto(completion: (() -> Void)? = nil) {
        PhotoAPIClient.shared.fetchReceivedToday { [weak self] response in
            DispatchQueue.main.async {
                self?.receivedPhoto = response
                completion?()
            }
        }
    }

    /// 받은 사진 '열어보기': 서버에서 잠금을 풀고, 성공하면 receivedPhoto 를 열린 응답으로 교체한다.
    func openReceivedPhoto(completion: @escaping (Bool) -> Void) {
        guard let shareId = receivedPhoto?.shareId else {
            completion(false)
            return
        }

        PhotoAPIClient.shared.openReceived(shareId: shareId) { [weak self] response in
            DispatchQueue.main.async {
                if let response = response, !response.locked, response.imageUrl != nil {
                    self?.receivedPhoto = response
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    /// 성공하면 받은 사진을 다시 조회해(리액션 반영) completion, 실패하면 onFailure 호출.
    /// 서버는 같은 사진에 같은 리액션을 두 번 보내는 것을 막는다.
    func sendSelectedReaction(
        type: PhotoReactionType,
        completion: @escaping () -> Void,
        onFailure: (() -> Void)? = nil
    ) {
        guard let shareId = receivedPhoto?.shareId else {
            onFailure?()
            return
        }

        PhotoAPIClient.shared.sendReaction(shareId: shareId, type: type) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.refreshReceivedPhoto()
                    completion()
                } else {
                    onFailure?()
                }
            }
        }
    }
}
