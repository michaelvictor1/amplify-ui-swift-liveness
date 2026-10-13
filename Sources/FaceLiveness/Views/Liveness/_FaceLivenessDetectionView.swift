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

            VStack(alignment: .trailing, spacing: 12) {
                if cancelButtonOptions.resolved != .hidden {
                    CancelButton(
                        options: cancelButtonOptions,
                        action: viewModel.closeButtonAction
                    )
                }

                InstructionContainerView(viewModel: viewModel)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}
