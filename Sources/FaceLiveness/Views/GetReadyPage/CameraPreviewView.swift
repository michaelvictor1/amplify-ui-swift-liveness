//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CameraPreviewView: View {
    private static let previewWidthRatio = 0.6
    private static let previewHeightRatio = 0.55
    private static let previewXPositionRatio = 0.5
    /// Same center as the scanning oval, which sits in the middle of the camera.
    private static let previewYPositionRatio = 0.5

    @StateObject var model: CameraPreviewViewModel
    var onReadyOval: (CGRect) -> Void = { _ in }

    init(
        cameraPosition: LivenessCamera,
        sharedCaptureSession: LivenessCaptureSession? = nil,
        onReadyOval: @escaping (CGRect) -> Void = { _ in }
    ) {
        self._model = StateObject(wrappedValue: CameraPreviewViewModel(
            cameraPosition: cameraPosition,
            sharedCaptureSession: sharedCaptureSession
        ))
        self.onReadyOval = onReadyOval
    }

    var body: some View {
        ZStack {
            ImageFrameView(image: model.currentImageFrame)
                .edgesIgnoringSafeArea(.all)
                .mask(
                    GeometryReader { geometry in
                        Ellipse()
                            .frame(width: geometry.size.width*Self.previewWidthRatio,
                                   height: geometry.size.height*Self.previewHeightRatio)
                            .position(x: geometry.size.width*Self.previewXPositionRatio,
                                      y: geometry.size.height*Self.previewYPositionRatio)
                    })
            GeometryReader { geometry in
                Ellipse()
                    .stroke(Color.livenessPreviewBorder, style: StrokeStyle(lineWidth: 3))
                    .frame(width: geometry.size.width*Self.previewWidthRatio,
                           height: geometry.size.height*Self.previewHeightRatio)
                    .position(x: geometry.size.width*Self.previewXPositionRatio,
                              y: geometry.size.height*Self.previewYPositionRatio)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ReadyOvalFrameKey.self,
                    value: Self.ovalFrame(in: geometry)
                )
            }
        )
        .onPreferenceChange(ReadyOvalFrameKey.self, perform: onReadyOval)
        .onDisappear {
            model.stopSession()
        }
    }

    /// The preview ellipse in screen coordinates.
    private static func ovalFrame(in geometry: GeometryProxy) -> CGRect {
        let size = geometry.size
        let width = size.width * previewWidthRatio
        let height = size.height * previewHeightRatio
        let local = CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
        let origin = geometry.frame(in: .global).origin
        return local.offsetBy(dx: origin.x, dy: origin.y)
    }
}

private struct ReadyOvalFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 0 { value = next }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(cameraPosition: .front)
    }
}
