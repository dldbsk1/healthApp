//
//  CameraCaptureController.swift
//  TipsyCut
//

import AVFoundation
import UIKit

extension UIImage {

    /// CIContext는 만들 때 비용이 크므로 앱 전체에서 하나만 재사용
    private static let sharedCIContext = CIContext()

    convenience init?(sampleBuffer: CMSampleBuffer) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let cgImage = UIImage.sharedCIContext.createCGImage(
            ciImage,
            from: ciImage.extent
        ) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}


// MARK: - Camera Capture Controller

final class CameraCaptureController: NSObject,
                                      ObservableObject,
                                      AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    private let queue = DispatchQueue(
        label: "camera.frame.queue"
    )

    weak var poseClient: PoseWebSocketClient?

    // MARK: - Start

    func start() {

        guard session.inputs.isEmpty else {
            queue.async {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
            return
        }

        // ⚠️ 시뮬레이터에는 카메라가 없어서 여기서 항상 실패함 → 실기기에서 테스트
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ),
        let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("❌ 전면 카메라를 가져올 수 없습니다. (시뮬레이터이거나 카메라 권한 없음)")
            return
        }

        session.beginConfiguration()

        // 720p(16:9) 고정 → 세로로 돌리면 정확히 9:16.
        // SkeletonOverlayView의 9:16 가정과 맞고, 전송량도 크게 줄어든다.
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()

        output.alwaysDiscardsLateVideoFrames = true

        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]

        output.setSampleBufferDelegate(
            self,
            queue: queue
        )

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        // 서버로 보내는 영상도 화면과 동일하게 세로 + 전면카메라 미러링
        if let connection = output.connection(with: .video) {

            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            if connection.isVideoMirroringSupported {
                // 수동으로 미러링을 지정하려면 자동 조정을 먼저 꺼야 함
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()

        queue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }


    // MARK: - Stop

    func stop() {

        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }


    // MARK: - Capture Output

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        // 전송할 차례가 아니면 이미지 변환 자체를 건너뜀
        // (기존에는 30fps 전부를 UIImage로 변환한 뒤에야 걸러서 CPU를 낭비함)
        guard let client = poseClient,
              client.reserveFrameSlot()
        else {
            return
        }

        guard let image = UIImage(sampleBuffer: sampleBuffer) else {
            client.releaseFrameSlot()
            return
        }

        client.sendFrame(image)
    }
}
