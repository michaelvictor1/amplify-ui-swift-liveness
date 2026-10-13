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
    let cameraPosition: LivenessCamera
    let sharedCaptureSession: LivenessCaptureSession?
    
    init(
        onBegin: @escaping () -> Void,
        beginCheckButtonDisabled: Bool = false,
        cameraPosition: LivenessCamera,
        sharedCaptureSession: LivenessCaptureSession? = nil
    ) {
        self.onBegin = onBegin
        self.beginCheckButtonDisabled = beginCheckButtonDisabled
        self.cameraPosition = cameraPosition
        self.sharedCaptureSession = sharedCaptureSession
    }

    var body: some View {
        VStack {
            ZStack {
                CameraPreviewView(cameraPosition: cameraPosition, sharedCaptureSession: sharedCaptureSession)
                VStack {
                    Text(LocalizedStrings.preview_center_your_face_text)
                        .font(theme.fonts.title)
                        .foregroundColor(theme.colors.onBackground)
                        .multilineTextAlignment(.center)
                    Spacer()
                }.padding()
            }
            beginCheckButton
        }
    }

    private var beginCheckButton: some View {
        Button(
            action: onBegin,
            label: {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
            }
        )
        .disabled(beginCheckButtonDisabled)
        .frame(height: 52)
        ._background { theme.colors.primary }
        .cornerRadius(14)
        .padding([.leading, .trailing])
        .padding(.bottom, 16)
    }
}

struct GetReadyPageView_Previews: PreviewProvider {
    static var previews: some View {
        GetReadyPageView(
            onBegin: {},
            cameraPosition: .front)
    }
}
