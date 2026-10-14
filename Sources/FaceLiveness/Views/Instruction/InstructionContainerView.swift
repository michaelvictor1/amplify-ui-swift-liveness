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

        case .awaitingFaceInOvalMatch(let reason, _):
            line(reason.localizedValue)

        case .recording(ovalDisplayed: true):
            line(LocalizedStrings.challenge_instruction_move_face_closer)
                .onAppear { announce(LocalizedStrings.challenge_instruction_move_face_closer) }

        case .pendingFacePreparedConfirmation(let reason):
            line(reason.localizedValue)

        case .completedDisplayingFreshness, .completedNoLightCheck:
            // The white cover announces this. A visible line would sit on that field.
            EmptyView()

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

    private func line(_ text: String, color: Color? = nil) -> some View {
        InstructionView(text: text, color: color)
    }

    private func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
