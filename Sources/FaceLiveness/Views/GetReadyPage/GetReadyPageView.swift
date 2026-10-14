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
    let cameraPosition: LivenessCamera
    let sharedCaptureSession: LivenessCaptureSession?
    
    init(
        onBegin: @escaping () -> Void,
        onClose: @escaping () -> Void,
        beginCheckButtonDisabled: Bool = false,
        cameraPosition: LivenessCamera,
        sharedCaptureSession: LivenessCaptureSession? = nil
    ) {
        self.onBegin = onBegin
        self.onClose = onClose
        self.beginCheckButtonDisabled = beginCheckButtonDisabled
        self.cameraPosition = cameraPosition
        self.sharedCaptureSession = sharedCaptureSession
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreviewView(cameraPosition: cameraPosition, sharedCaptureSession: sharedCaptureSession)
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            beginCheckButton
        }
    }

    @ViewBuilder
    private var beginCheckButton: some View {
        if #available(iOS 26, *) {
            Button(action: onBegin) {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(theme.fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(theme.colors.primary)
            .disabled(beginCheckButtonDisabled)
            .padding([.leading, .trailing])
            .padding(.bottom, 16)
        } else {
            Button(action: onBegin) {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
            }
            .disabled(beginCheckButtonDisabled)
            .frame(height: 52)
            ._background { theme.colors.primary }
            .cornerRadius(14)
            .padding([.leading, .trailing])
            .padding(.bottom, 16)
        }
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
