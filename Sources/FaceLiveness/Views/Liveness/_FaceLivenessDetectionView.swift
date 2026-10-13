//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

struct _FaceLivenessDetectionView<VideoView: View>: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
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
        VStack(spacing: 0) {
            ZStack {
                Color.black
                videoView

                VStack {
                    InstructionContainerView(viewModel: viewModel)
                    Spacer()
                }
                .padding()
            }

            if cancelButtonOptions.resolved != .hidden {
                cancelButton
            }
        }
    }

    /// Same slot as Verify Me. Solid pill, same fill and type as Not Now.
    private var cancelButton: some View {
        Button(action: viewModel.closeButtonAction) {
            Text(LocalizedStrings.cancel)
                .font(theme.fonts.body)
                .fontWeight(.semibold)
                .foregroundColor(cancelLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background(cancelFill)
        .clipShape(Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var cancelFill: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.hex("#101828")
                : UIColor.hex("#F9FAFB")
        })
    }

    private var cancelLabel: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.hex("#D0D5DD")
                : UIColor.hex("#475467")
        })
    }
}
