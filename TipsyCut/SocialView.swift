import SwiftUI

struct SocialView: View {

    // MARK: - ViewModel
    // 최상위 탭 바에서 주입받아 사용
    @EnvironmentObject private var viewModel: SocialViewModel

    // MARK: - UI State
    @State private var showCamera = false
    @State private var selectedReaction: PhotoReactionType? = nil
    @State private var showAddConfirmationAlert = false

    // 받은 사진이 아직 없을 때 보여줄 알림
    @State private var showNoReceivedPhotoAlert = false

    // 서버에서 열기에 실패했을 때 보여줄 알림
    @State private var showOpenFailedAlert = false

    // '열어보기' 요청 진행 중
    @State private var isOpeningReceived = false

    // 리액션 전송 실패 알림
    @State private var showReactionFailedAlert = false

    // MARK: - Reaction
    private let reactions = PhotoReactionType.allCases

    // MARK: - 받은 사진 상태 (잠금 여부는 서버가 결정한다)

    /// 오늘 도착한 사진이 있는지 (서버는 사진이 없을 때도 locked 응답 + shareId == nil 로 내려준다)
    private var hasArrivedPhoto: Bool {
        viewModel.receivedPhoto?.shareId != nil
    }

    /// 서버에서 잠금이 풀려 imageUrl 을 받은 상태
    private var isReceivedOpened: Bool {
        guard let received = viewModel.receivedPhoto else {
            return false
        }
        return !received.locked && received.imageUrl != nil
    }

    private var canReact: Bool {
        isReceivedOpened && hasArrivedPhoto
    }

    /// 이 받은 사진에 내가 이미 보낸 리액션 종류 (서버는 같은 리액션 중복 전송을 막는다)
    private var sentReactionTypes: Set<PhotoReactionType> {
        Set((viewModel.receivedPhoto?.reactions ?? []).map { $0.reactionType })
    }

    private var canSendReaction: Bool {
        guard let selected = selectedReaction else {
            return false
        }
        return canReact && !sentReactionTypes.contains(selected)
    }

    var body: some View {

        ZStack(alignment: .bottomTrailing) {

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - 상단 문구
                    VStack(alignment: .leading, spacing: 4) {

                        Text("오늘도 수고했어요!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("오늘의 순간을 기록해보세요 📸")
                            .font(.subheadline)
                            .foregroundColor(.subColor)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // MARK: - 내 사진
                    HStack {
                        Spacer()

                        ZStack {

                            // 1. 방금 촬영한 이미지
                            if let image = viewModel.selectedImage {

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                buildRecordBadge()
                            }

                            // 2. 서버에서 불러온 오늘의 사진
                            else if let urlString = viewModel.uploadedPhotoURL,
                                    let url = AppConfig.resolvedImageURL(urlString) {

                                remotePhoto(
                                    url,
                                    failureText: nil,
                                    placeholder: Color(.systemGray6)
                                )

                                buildRecordBadge()
                            }

                            // 3. 오늘 사진이 없는 경우
                            else {

                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 300, height: 300)
                                    .overlay {

                                        Text("오늘 기록을 등록하면\n랜덤으로 다른 유저와 사진을 교환해요!")
                                            .font(.footnote)
                                            .foregroundColor(.subColor)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                            }

                            // 상대가 내 사진에 보낸 리액션 (오른쪽 아래)
                            reactionBadge(
                                viewModel.myPhotoReactions,
                                alignment: .bottomTrailing
                            )

                            // 업로드 중
                            if viewModel.isUploading {

                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.35))
                                    .frame(width: 300, height: 300)

                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(width: 300, height: 300)

                        Spacer()
                    }
                    .padding(.vertical, 10)

                    // MARK: - 업로드 에러
                    if let errorMessage = viewModel.uploadErrorMessage {

                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // MARK: - 사진 등록 버튼
                    Button {

#if targetEnvironment(simulator)

                        // 시뮬레이터에서는 Assets 이미지 사용
                        if let assetImage = UIImage(named: "1") {

                            viewModel.selectedImage = assetImage
                            viewModel.uploadPhoto(assetImage)

                        } else {

                            print("⚠️ Assets에 '1' 이미지가 없습니다!")
                        }

#else

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        }

#endif

                    } label: {

                        HStack(spacing: 8) {

                            Image(systemName: "camera")
                                .font(.system(size: 16))

                            Text(
                                viewModel.uploadedPhotoURL != nil ||
                                viewModel.selectedImage != nil
                                ? "다시 찍기 (덮어쓰기)"
                                : "사진 등록하기"
                            )
                            .font(.headline)
                        }
                        .foregroundColor(.mintColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mintTint.opacity(0.3))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    .disabled(viewModel.isUploading)

                    // MARK: - 받은 사진
                    VStack(alignment: .leading, spacing: 12) {

                        HStack {

                            Text("받은 사진")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            Button {

                                viewModel.refreshReceivedPhoto()
                                viewModel.fetchMyTodayPhoto()

                            } label: {

                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.mintColor)
                            }
                        }
                        .padding(.horizontal)

                        // 받은 사진 박스
                        HStack {
                            Spacer()

                            receivedPhotoBox
                                .frame(width: 300, height: 300)

                            Spacer()
                        }

                        // MARK: - 리액션
                        HStack(spacing: 12) {

                            ForEach(reactions, id: \.self) { reaction in

                                Button {

                                    selectedReaction = reaction

                                } label: {

                                    Text(reaction.emoji)
                                        .font(.system(size: 28))
                                        .padding(10)
                                        .background(
                                            selectedReaction == reaction
                                            ? Color.selectedMint
                                            : Color(.systemGray6)
                                        )
                                        .clipShape(Circle())
                                        .overlay {

                                            Circle()
                                                .stroke(
                                                    selectedReaction == reaction
                                                    ? Color.mintColor
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        }
                                }
                                .disabled(sentReactionTypes.contains(reaction))
                                .opacity(sentReactionTypes.contains(reaction) ? 0.35 : 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .opacity(canReact ? 1 : 0.4)
                        .disabled(!canReact)

                        // MARK: - 리액션 보내기
                        Button {

                            showAddConfirmationAlert = true

                        } label: {

                            Text("리액션 보내기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    canSendReaction
                                    ? Color.mintColor
                                    : Color.subColor
                                )
                                .cornerRadius(14)
                                .padding(.horizontal)
                        }
                        .disabled(!canSendReaction)
                        .alert(
                            "\(selectedReaction?.emoji ?? "")을 보내시겠습니까?",
                            isPresented: $showAddConfirmationAlert
                        ) {

                            Button("취소", role: .cancel) {
                            }

                            Button("확인") {

                                guard let reaction = selectedReaction else {
                                    return
                                }

                                viewModel.sendSelectedReaction(
                                    type: reaction,
                                    completion: {
                                        selectedReaction = nil
                                    },
                                    onFailure: {
                                        showReactionFailedAlert = true
                                    }
                                )
                            }

                        } message: {

                            Text("상대방의 피드에 해당 리액션이 등록됩니다.")
                        }

                        .padding(.bottom, 80)
                    }
                }
            }
            .refreshable {

                viewModel.refreshReceivedPhoto()
                viewModel.fetchMyTodayPhoto()
            }

            // MARK: - 플로팅 캘린더 버튼
            NavigationLink(
                destination: SocialCalendarView()
            ) {

                Image(systemName: "calendar")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.mintColor)
                    .clipShape(Circle())
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }

        // MARK: - 카메라
        .sheet(isPresented: $showCamera) {

            CameraView(image: $viewModel.selectedImage)
        }

        // MARK: - 촬영 후 업로드
        .onChange(of: viewModel.selectedImage) { newImage in

            guard let newImage else {
                return
            }

            viewModel.uploadPhoto(newImage)
        }

        // MARK: - 새로운 사진이 도착하면 이전 리액션 선택 초기화
        .onChange(of: viewModel.receivedPhoto?.shareId) { _ in

            selectedReaction = nil
        }

        // MARK: - 받은 사진 없음 알림
        .alert(
            "받은 사진이 없습니다",
            isPresented: $showNoReceivedPhotoAlert
        ) {

            Button("확인", role: .cancel) {
            }

        } message: {

            Text("아직 다른 사용자에게 받은 사진이 없어요.")
        }

        // MARK: - 열기 실패 알림
        .alert(
            "사진을 열 수 없어요",
            isPresented: $showOpenFailedAlert
        ) {

            Button("확인", role: .cancel) {
            }

        } message: {

            Text("잠시 후 다시 시도해 주세요.")
        }

        // MARK: - 리액션 전송 실패 알림
        .alert(
            "리액션을 보내지 못했어요",
            isPresented: $showReactionFailedAlert
        ) {

            Button("확인", role: .cancel) {
            }

        } message: {

            Text("이미 같은 리액션을 보냈거나 일시적인 오류일 수 있어요.")
        }

        // MARK: - 화면 진입
        .onAppear {

            viewModel.refreshReceivedPhoto()
            viewModel.fetchMyTodayPhoto()
        }
    }

    // MARK: - 받은 사진 박스

    @ViewBuilder
    private var receivedPhotoBox: some View {

        ZStack {

            if let received = viewModel.receivedPhoto,
               received.shareId != nil {

                // 서버에서 잠금이 풀린 사진 → 바로 표시
                if !received.locked,
                   let urlString = received.imageUrl,
                   let url = AppConfig.resolvedImageURL(urlString) {

                    ZStack {

                        remotePhoto(
                            url,
                            failureText: "사진을 불러오지 못했어요",
                            placeholder: Color(.systemGray5)
                        )

                        // 내가 이 사진에 보낸 리액션 (왼쪽 위)
                        reactionBadge(
                            received.reactions,
                            alignment: .topLeading
                        )
                    }

                }

                // 사진은 도착했지만 아직 안 연 상태
                else {

                    lockedBox
                }

            }

            // 오늘 받은 사진이 아직 없는 경우
            else {

                emptyBox
            }
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - 도착했지만 잠긴 상태

    private var lockedBox: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(width: 300, height: 300)

            VStack(spacing: 16) {

                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.subColor)

                Text("새로운 사진이 도착했어요!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.subColor)

                Button {

                    guard !isOpeningReceived else {
                        return
                    }

                    isOpeningReceived = true
                    selectedReaction = nil

                    // 서버에서 잠금을 풀고 imageUrl 을 받아온다
                    viewModel.openReceivedPhoto { success in

                        isOpeningReceived = false

                        if !success {
                            showOpenFailedAlert = true
                        }
                    }

                } label: {

                    ZStack {

                        if isOpeningReceived {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("열어보기")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 140, height: 46)
                    .background(Color.mintColor)
                    .cornerRadius(12)
                }
                .disabled(isOpeningReceived)
            }
        }
    }

    // MARK: - 받은 사진 자체가 없는 상태

    private var emptyBox: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(width: 300, height: 300)

            VStack(spacing: 16) {

                Image(systemName: "tray.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.subColor)

                Text("아직 도착한 사진이 없어요")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.subColor)

                Button {

                    // 새로 도착했는지 서버에 다시 확인
                    viewModel.refreshReceivedPhoto {

                        if viewModel.receivedPhoto?.shareId == nil {
                            showNoReceivedPhotoAlert = true
                        }
                    }

                } label: {

                    Text("열어보기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 46)
                        .background(Color.mintColor)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 원격 이미지 (내 사진 / 받은 사진 공통)

    @ViewBuilder
    private func remotePhoto(
        _ url: URL,
        failureText: String?,
        placeholder: Color
    ) -> some View {

        AsyncImage(url: url) { phase in

            switch phase {

            case .success(let image):

                image
                    .resizable()
                    .scaledToFill()

            case .failure:

                ZStack {

                    placeholder

                    VStack(spacing: 8) {

                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.subColor)

                        if let failureText {

                            Text(failureText)
                                .font(.subheadline)
                                .foregroundColor(.subColor)
                        }
                    }
                }

            case .empty:

                ZStack {
                    placeholder
                    ProgressView()
                }

            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 리액션 배지

    /// 같은 종류는 묶어서 [(종류, 개수)] 로 (처음 나온 순서 유지)
    private func groupedReactions(
        _ reactions: [PhotoReactionResponse]
    ) -> [(type: PhotoReactionType, count: Int)] {

        var order: [PhotoReactionType] = []
        var counts: [PhotoReactionType: Int] = [:]

        for reaction in reactions {

            if counts[reaction.reactionType] == nil {
                order.append(reaction.reactionType)
            }

            counts[reaction.reactionType, default: 0] += 1
        }

        return order.map { (type: $0, count: counts[$0] ?? 0) }
    }

    /// 사진(300x300) 위에 겹쳐 올리는 이모지 배지. 리액션이 없으면 아무것도 그리지 않는다.
    @ViewBuilder
    private func reactionBadge(
        _ reactions: [PhotoReactionResponse],
        alignment: Alignment
    ) -> some View {

        let groups = groupedReactions(reactions)

        if !groups.isEmpty {

            HStack(spacing: 8) {

                ForEach(groups, id: \.type) { group in

                    HStack(spacing: 3) {

                        Text(group.type.emoji)
                            .font(.system(size: 22))

                        if group.count > 1 {

                            Text("\(group.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
            .padding(12)
            .frame(width: 300, height: 300, alignment: alignment)
        }
    }

    // MARK: - 오늘의 기록 배지

    @ViewBuilder
    private func buildRecordBadge() -> some View {

        VStack {

            HStack {

                Spacer()

                Text(
                    viewModel.isUploading
                    ? "업로드 중..."
                    : "📷 오늘의 기록"
                )
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .padding([.top, .trailing], 12)
            }

            Spacer()
        }
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        SocialView()
            .environmentObject(SocialViewModel())
    }
}
