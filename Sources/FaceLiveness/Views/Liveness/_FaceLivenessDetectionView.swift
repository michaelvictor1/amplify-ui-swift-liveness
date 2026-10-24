//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// `text.tertiary`. A static stored property on the generic view below does not compile.
private let faceCheckNoteColor = Color(uiColor: UIColor { traits in
    traits.userInterfaceStyle == .dark
        ? UIColor.hex("#98A2B3")
        : UIColor.hex("#667085")
})

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
    /// The note uses the explainer legal size: 12pt regular, line height 20, text.tertiary.
    @ViewBuilder
    private var progressBelowOval: some View {
        if let percentage = fitProgress, viewModel.ovalRect.height > 0 {
            GeometryReader { geo in
                let preview = LivenessPreviewGeometry.previewRect(fittingIn: geo.size)
                let barTop = preview.minY + viewModel.ovalRect.maxY + 52
                Color.clear
                    .overlay(alignment: .top) {
                        VStack(spacing: 8) {
                            ProgressBarView(percentage: percentage)
                            Text(LocalizedStrings.challenge_fit_note)
                                .font(.system(size: 12, weight: .regular))
                                .lineSpacing(Self.noteLeading)
                                .foregroundColor(faceCheckNoteColor)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: geo.size.width - 48)
                        }
                        .offset(y: barTop)
                    }
            }
            .allowsHitTesting(false)
        }
    }

    /// Extra leading so the line box matches the explainer note’s `lineHeight` of 20.
    private static var noteLeading: CGFloat {
        let natural = UIFont.systemFont(ofSize: 12, weight: .regular).lineHeight
        return max(0, 20 - natural)
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
