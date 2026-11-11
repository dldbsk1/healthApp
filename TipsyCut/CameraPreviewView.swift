//
//  CameraPreviewView.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 10/1/26.
//
/*
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        // 전면 카메라 미러링 (기본적으로 전면 카메라는 자동 미러링됨)
        if let connection = view.videoPreviewLayer.connection {
            connection.automaticallyAdjustsVideoMirroring = true
        }
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
*/
