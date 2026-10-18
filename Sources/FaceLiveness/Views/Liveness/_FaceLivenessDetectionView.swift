//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

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
            progressBelowOval
        }
    }

    /// Fit progress sits under the oval, not under the direction line.
    @ViewBuilder
    private var progressBelowOval: some View {
        if let percentage = fitProgress, viewModel.ovalRect.height > 0 {
            GeometryReader { geo in
                let preview = LivenessPreviewGeometry.previewRect(fittingIn: geo.size)
                let barHeight: CGFloat = 7
                let y = preview.minY + viewModel.ovalRect.maxY + 52 + barHeight / 2
                ProgressBarView(percentage: percentage)
                    .position(x: geo.size.width / 2, y: y)
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
