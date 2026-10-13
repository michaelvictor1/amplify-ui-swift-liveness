//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// Same track as Create Account, a little wider: 140×7, fully rounded.
/// Light track is brand.100, dark track is brand.700, fill is brand primary.
struct ProgressBarView: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
    let percentage: Double

    private let trackWidth: CGFloat = 140
    private let trackHeight: CGFloat = 7

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(trackColor)
                .frame(width: trackWidth, height: trackHeight)
            Capsule()
                .fill(theme.colors.primary)
                .frame(width: trackWidth * clamped, height: trackHeight)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var clamped: CGFloat {
        CGFloat(min(max(percentage, 0), 1))
    }

    private var trackColor: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.hex("#001258")
                : UIColor.hex("#E2E7F7")
        })
    }
}
