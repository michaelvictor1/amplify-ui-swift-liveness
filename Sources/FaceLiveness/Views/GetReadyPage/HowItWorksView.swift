//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// Shown before Center your face. Title, subtitle, three steps, and Verify Me.
struct HowItWorksView: View {
    @Environment(\.faceLivenessDetectorTheme) private var theme
    let onBegin: () -> Void
    let onClose: () -> Void

    private let steps: [(symbol: String, label: String)] = [
        ("sun.max.fill", LocalizedStrings.how_it_works_step_one),
        ("face.smiling.fill", LocalizedStrings.how_it_works_step_two),
        ("sunglasses.fill", LocalizedStrings.how_it_works_step_three),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
        VStack(spacing: 0) {
            VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text(LocalizedStrings.how_it_works_title)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.colors.onBackground)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Text(LocalizedStrings.how_it_works_subtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Self.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 80)

                    VStack(alignment: .leading, spacing: 20) {
                        Text(LocalizedStrings.how_it_works_before)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Self.secondaryText)
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                            HStack(alignment: .center, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Self.brandWash)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: step.symbol)
                                        .font(.system(size: 22, weight: .regular))
                                        .foregroundColor(Self.brandIcon)
                                }
                                Text(step.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineSpacing(4)
                                    .foregroundColor(theme.colors.onBackground)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 48)
                        }
                    }
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            VStack(spacing: 20) {
                Text(LocalizedStrings.how_it_works_legal)
                    .font(.system(size: 12, weight: .regular))
                    .lineSpacing(4)
                    .foregroundColor(Self.tertiaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                verifyButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
            CloseButton(action: onClose)
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
    }

    private var verifyButton: some View {
        LivenessPrimaryButton(
            title: LocalizedStrings.get_ready_begin_check,
            action: onBegin
        )
    }

    private static let brandIcon = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.hex("#476EFF")
            : UIColor.hex("#315CFF")
    })
    private static let brandWash = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.hex("#000B37")
            : UIColor.hex("#EFF1FA")
    })

    private static let tertiaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.hex("#98A2B3")
            : UIColor.hex("#475467")
    })

    private static let secondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.hex("#D0D5DD")
            : UIColor.hex("#344054")
    })
}
