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

    private let steps: [(symbol: String, label: String)] = [
        ("sun.max.fill", LocalizedStrings.how_it_works_step_one),
        ("face.smiling.fill", LocalizedStrings.how_it_works_step_two),
        ("nosign", LocalizedStrings.how_it_works_step_three),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
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
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 20) {
                        Text(LocalizedStrings.how_it_works_before)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Self.secondaryText)
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Self.betaWash)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: step.symbol)
                                        .font(.system(size: 22, weight: .regular))
                                        .foregroundColor(Self.betaIcon)
                                }
                                Text(step.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(theme.colors.onBackground)
                                    .padding(.top, 4)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 48)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            verifyButton
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var verifyButton: some View {
        if #available(iOS 26, *) {
            Button(action: onBegin) {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(theme.fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(theme.colors.primary)
        } else {
            Button(action: onBegin) {
                Text(LocalizedStrings.get_ready_begin_check)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.onPrimary)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 52)
            ._background { theme.colors.primary }
            .cornerRadius(14)
        }
    }

    private static let betaIcon = Color(uiColor: UIColor.hex("#9A16B0"))
    private static let betaWash = Color(uiColor: UIColor.hex("#FEF8FF"))

    private static let secondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.hex("#D0D5DD")
            : UIColor.hex("#344054")
    })
}
