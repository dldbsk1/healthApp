//
//  CameraCaptureController.swift
//  TipsyCut
//

import AVFoundation
import UIKit

extension UIImage {
    convenience init?(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        self.init(cgImage: cgImage)
    }
}

// 💡 class 선언부에 ObservableObject 프로토콜 추가 및 session 접근성 확보
final class CameraCaptureController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.frame.queue")
    weak var poseClient: PoseWebSocketClient?

    func start() {
        guard session.inputs.isEmpty else {
            queue.async { self.session.startRunning() }
            return
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        queue.async { self.session.startRunning() }
    }

    func stop() {
        queue.async { self.session.stopRunning() }
    }

    func captureOutput(_ output: AVCaptureOutput,
                        didOutput sampleBuffer: CMSampleBuffer,
                        from connection: AVCaptureConnection) {
        guard let image = UIImage(sampleBuffer: sampleBuffer) else { return }
        poseClient?.sendFrame(image)
    }
}
