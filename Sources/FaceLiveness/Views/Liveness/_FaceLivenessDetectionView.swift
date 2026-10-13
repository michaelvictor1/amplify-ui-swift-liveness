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

    /// Where the preview's top and the bottom of the close button row are, in the `layoutSpace`
    /// coordinate space.
    @State private var previewMinY: CGFloat = 0
    @State private var controlsMaxY: CGFloat = 0

    /// Gap between the instruction and the top of the oval.
    private let instructionOvalGap: CGFloat = 16

    /// The instruction is inset 24pt from the preview's edges while the face guide is on screen
    /// and 16pt otherwise.
    private var instructionPadding: CGFloat {
        viewModel.livenessState.isFaceGuideDisplayed ? 24 : 16
    }

    private var instructionTopInset: CGFloat {
        LivenessPreviewGeometry.instructionTopInset(
            instructionPadding,
            previewMinY: previewMinY,
            controlsMaxY: controlsMaxY
        )
    }

    /// Face-fit lines sit in one band that ends above the oval. Before the oval is drawn they
    /// stay at the top of the preview.
    private var instructionBandAboveOval: (top: CGFloat, height: CGFloat)? {
        let ovalTop = viewModel.ovalRect.minY
        guard viewModel.livenessState.isFaceGuideDisplayed, ovalTop > 0 else { return nil }
        return LivenessPreviewGeometry.instructionBandAboveOval(
            ovalTop: ovalTop,
            gap: instructionOvalGap,
            buttonClearance: instructionTopInset
        )
    }

    var body: some View {
        ZStack {
            ZStack {
                Color.black
                videoView

                Color.clear
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(alignment: .top) {
                    instructionLayer
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: PreviewMinYKey.self,
                            value: proxy.frame(in: .named(layoutSpace)).minY
                        )
                    }
                )
                .frame(maxWidth: .infinity)
            }
            .edgesIgnoringSafeArea(.all)

            // The close button stays in the top corner. The instruction sits above the oval.
            VStack {
                HStack(alignment: .top) {
                    Spacer()

                    CancelButton(
                        options: cancelButtonOptions,
                        action: viewModel.closeButtonAction
                    )
                }
                .padding(16)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ControlsMaxYKey.self,
                            value: proxy.frame(in: .named(layoutSpace)).maxY
                        )
                    }
                )

                Spacer()
            }
        }
        .coordinateSpace(name: layoutSpace)
        .onPreferenceChange(PreviewMinYKey.self) { previewMinY = $0 ?? previewMinY }
        .onPreferenceChange(ControlsMaxYKey.self) { controlsMaxY = $0 ?? controlsMaxY }
    }

    @ViewBuilder
    private var instructionLayer: some View {
        if let band = instructionBandAboveOval {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                InstructionContainerView(viewModel: viewModel)
            }
            .padding(.horizontal, instructionPadding)
            .frame(height: band.height, alignment: .bottom)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, band.top)
        } else {
            VStack(spacing: 5) {
                InstructionContainerView(viewModel: viewModel)
                Spacer(minLength: 0)
            }
            .padding(.top, instructionTopInset)
            .padding(.horizontal, instructionPadding)
        }
    }
}

private let layoutSpace = "FaceLivenessDetectionLayout"

/// Optional so a view that doesn't measure, and so contributes the default, can't overwrite a
/// measurement while the values are combined.
private struct PreviewMinYKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

private struct ControlsMaxYKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}
