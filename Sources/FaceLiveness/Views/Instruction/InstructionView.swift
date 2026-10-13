//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Same treatment as "Center your face": title, on-background, centered, no chip.
struct InstructionView: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
    let text: String

    var body: some View {
        Text(text)
            .font(theme.fonts.title)
            .foregroundColor(theme.colors.onBackground)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
