//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A static stored property on the generic view below does not compile.
private let faceCheckBarClearance: CGFloat = 52
private let faceCheckBarHeight: CGFloat = 7
/// Close row + direction line, then `faceCheckBarClearance` before the bar.
private let faceCheckMinBarTop: CGFloat = 16 + 44 + 12 + 36 + 52

struct _FaceLivenessDetectionView<VideoView: View>: View {
    let videoView: VideoView
    @ObservedObject var viewModel: FaceLivenessDetectionViewModel
    @Binding var displayResultsView: Bool
    let cancelButtonOptions: CancelButtonOptions

    init(
        viewModel: FaceLivenessDetectionViewModel,
        cancelButtonOptions: CancelButtonOptions = .init(),
        @ViewBuilder videoView: @escaping () -> VideoView
    ) {
        self.viewModel = viewModel
        self.cancelButtonOptions = cancelButtonOptions
        self.videoView = videoView()

        self._displayResultsView = .init(
            get: { viewModel.livenessState.state == .completed },
            set: { _ in }
        )
    }

    var body: some View {
        ZStack {
            Color.black
            videoView

            VStack(spacing: 12) {
                HStack {
                    Spacer(minLength: 0)
                    if cancelButtonOptions.resolved != .hidden {
                        CancelButton(
                            options: cancelButtonOptions,
                            action: viewModel.closeButtonAction
                        )
                    }
                }

                InstructionContainerView(viewModel: viewModel)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        // The page behind this check is white. Without this, that white shows
        // as a lip under the home indicator, including while the colors flash.
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            progressAboveOval
        }
    }

    /// Fit progress sits above the oval. Same show/hide as before.
    @ViewBuilder
    private var progressAboveOval: some View {
        if let percentage = fitProgress, viewModel.ovalRect.height > 0 {
            GeometryReader { geo in
                let preview = LivenessPreviewGeometry.previewRect(fittingIn: geo.size)
                let ovalTop = preview.minY + viewModel.ovalRect.minY
                let preferred = ovalTop - faceCheckBarClearance - faceCheckBarHeight
                let barTop = max(faceCheckMinBarTop, preferred)
                Color.clear
                    .overlay(alignment: .top) {
                        ProgressBarView(percentage: percentage)
                            .offset(y: barTop)
                    }
            }
            .allowsHitTesting(false)
        }
    }

    private var fitProgress: Double? {
        switch viewModel.livenessState.state {
        case .awaitingFaceInOvalMatch(.faceTooClose, _):
            return nil
        case .awaitingFaceInOvalMatch(_, let percentage):
            return percentage
        case .recording(ovalDisplayed: true):
            return 0.2
        default:
            return nil
        }
    }
}
