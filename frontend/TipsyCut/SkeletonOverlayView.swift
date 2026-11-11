//
//  SkeletonOverlayView.swift
//  TipsyCut
//

import SwiftUI

struct SkeletonOverlayView: View {

    /// 서버에서 전달받는 YOLO Pose 17개 관절
    /// 각 좌표는 0~1로 정규화되어 있음
    let keypoints: [CGPoint]

    // YOLO Pose 17개 관절 연결
    private let edges: [(Int, Int)] = [
        (0, 1), (0, 2),
        (1, 3), (2, 4),

        (5, 6),

        (5, 7),
        (7, 9),

        (6, 8),
        (8, 10),

        (5, 11),
        (6, 12),

        (11, 12),

        (11, 13),
        (13, 15),

        (12, 14),
        (14, 16)
    ]

    var body: some View {

        GeometryReader { geo in

            Canvas { context, size in

                guard keypoints.count == 17 else {
                    return
                }

                // --------------------------------------------------
                // 카메라 원본 비율
                //
                // CameraCaptureController에서 portrait로 설정했기
                // 때문에 화면에 표시되는 카메라는 9:16 기준.
                // --------------------------------------------------

                let cameraAspectRatio: CGFloat = 9.0 / 16.0

                let screenAspectRatio =
                    size.width / size.height

                // resizeAspectFill과 동일한 scale 계산
                let scale: CGFloat

                if screenAspectRatio > cameraAspectRatio {

                    // 화면이 카메라보다 가로로 넓음
                    scale = size.width / (cameraAspectRatio * size.height)

                } else {

                    // 화면이 카메라보다 세로로 넓음
                    scale = size.height / (size.width / cameraAspectRatio)
                }

                // 위 계산을 조금 더 안정적으로
                // "카메라 영상이 화면에서 실제 몇 px로 표시되는지" 계산

                let displayedWidth =
                    size.height * cameraAspectRatio

                let displayedHeight =
                    size.width / cameraAspectRatio

                let actualDisplayedWidth: CGFloat
                let actualDisplayedHeight: CGFloat

                if displayedWidth >= size.width {

                    actualDisplayedWidth = displayedWidth
                    actualDisplayedHeight = size.height

                } else {

                    actualDisplayedWidth = size.width
                    actualDisplayedHeight = displayedHeight
                }

                // 화면 밖으로 잘려 나가는 부분
                let cropX =
                    (actualDisplayedWidth - size.width) / 2

                let cropY =
                    (actualDisplayedHeight - size.height) / 2


                // --------------------------------------------------
                // 정규화 좌표 → 실제 화면 좌표
                // --------------------------------------------------

                func point(_ index: Int) -> CGPoint? {

                    guard index >= 0,
                          index < keypoints.count
                    else {
                        return nil
                    }

                    let p = keypoints[index]

                    // 서버에서 미검출 관절을 0,0으로 보내는 경우
                    guard p.x > 0.001 || p.y > 0.001 else {
                        return nil
                    }

                    // 서버 좌표
                    let sourceX = p.x * actualDisplayedWidth
                    let sourceY = p.y * actualDisplayedHeight

                    // resizeAspectFill로 잘린 만큼 보정
                    let x = sourceX - cropX
                    let y = sourceY - cropY

                    return CGPoint(
                        x: x,
                        y: y
                    )
                }


                // --------------------------------------------------
                // 뼈대
                // --------------------------------------------------

                for (a, b) in edges {

                    guard let pa = point(a),
                          let pb = point(b)
                    else {
                        continue
                    }

                    var path = Path()

                    path.move(to: pa)
                    path.addLine(to: pb)

                    context.stroke(
                        path,
                        with: .color(
                            .mintColor.opacity(0.9)
                        ),
                        lineWidth: 3
                    )
                }


                // --------------------------------------------------
                // 관절
                // --------------------------------------------------

                for i in 0..<17 {

                    guard let p = point(i) else {
                        continue
                    }

                    let dotSize: CGFloat = 8

                    let rect = CGRect(
                        x: p.x - dotSize / 2,
                        y: p.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.yellow)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
