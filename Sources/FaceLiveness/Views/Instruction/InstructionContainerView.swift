//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Combine
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

struct InstructionContainerView: View {
    @ObservedObject var viewModel: FaceLivenessDetectionViewModel

    var body: some View {
        switch viewModel.livenessState.state {
        case .displayingFreshness:
            line(LocalizedStrings.challenge_instruction_hold_still)
                .onAppear { announce(LocalizedStrings.challenge_instruction_hold_still) }

        case .awaitingFaceInOvalMatch(.faceTooClose, _):
            line(LocalizedStrings.challenge_instruction_move_face_back)
                .onAppear { announce(LocalizedStrings.challenge_instruction_move_face_back) }

        case .awaitingFaceInOvalMatch(let reason, let percentage):
            VStack(spacing: 16) {
                line(reason.localizedValue)
                ProgressBarView(percentage: percentage)
            }

        case .recording(ovalDisplayed: true):
            VStack(spacing: 16) {
                line(LocalizedStrings.challenge_instruction_move_face_closer)
                    .onAppear { announce(LocalizedStrings.challenge_instruction_move_face_closer) }
                ProgressBarView(percentage: 0.2)
            }

        case .pendingFacePreparedConfirmation(let reason):
            line(reason.localizedValue)

        case .completedDisplayingFreshness, .completedNoLightCheck:
            line(LocalizedStrings.challenge_verifying)
                .onAppear { announce(LocalizedStrings.challenge_verifying) }

        case .faceMatched:
            if let challenge = viewModel.challengeReceived,
               case .faceMovementAndLightChallenge = challenge {
                line(LocalizedStrings.challenge_instruction_hold_still)
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }

    private func line(_ text: String) -> some View {
        InstructionView(text: text)
    }

    private func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
