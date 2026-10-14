//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// 58pt tinted pill. Matches GlassButton: 16pt padding, a 24pt label, and a 1pt border.
struct LivenessPrimaryButton: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .glassEffect(.regular.tint(theme.colors.primary).interactive(), in: .capsule)
            .disabled(disabled)
        } else {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
            }
            .disabled(disabled)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            ._background { theme.colors.primary }
            .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
        }
    }
}
