//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

struct GetReadyPageView: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
    let beginCheckButtonDisabled: Bool
    let onBegin: () -> Void
    let onClose: () -> Void
    let onReadyOval: (CGRect) -> Void
    let cameraPosition: LivenessCamera
    let sharedCaptureSession: LivenessCaptureSession?
    
    init(
        onBegin: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onReadyOval: @escaping (CGRect) -> Void = { _ in },
        beginCheckButtonDisabled: Bool = false,
        cameraPosition: LivenessCamera,
        sharedCaptureSession: LivenessCaptureSession? = nil
    ) {
        self.onBegin = onBegin
        self.onClose = onClose
        self.onReadyOval = onReadyOval
        self.beginCheckButtonDisabled = beginCheckButtonDisabled
        self.cameraPosition = cameraPosition
        self.sharedCaptureSession = sharedCaptureSession
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreviewView(
                    cameraPosition: cameraPosition,
                    sharedCaptureSession: sharedCaptureSession,
                    onReadyOval: onReadyOval
                )
                VStack(spacing: 12) {
                    HStack {
                        Spacer(minLength: 0)
                        CloseButton(action: onClose)
                    }
                    Text(LocalizedStrings.preview_center_your_face_text)
                        .font(theme.fonts.title)
                        .foregroundColor(theme.colors.onBackground)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            beginCheckButton
        }
    }

    private var beginCheckButton: some View {
        LivenessPrimaryButton(
            title: LocalizedStrings.get_ready_im_ready,
            action: onBegin,
            disabled: beginCheckButtonDisabled
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

struct GetReadyPageView_Previews: PreviewProvider {
    static var previews: some View {
        GetReadyPageView(
            onBegin: {},
            onClose: {},
            cameraPosition: .front)
    }
}
