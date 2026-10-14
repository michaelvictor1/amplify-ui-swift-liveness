//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// 44pt glass circle, same role as the app's icon buttons.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel(LocalizedStrings.close_button_a11y)
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial)
                    .clipShape(Circle())
                    .accessibilityLabel(LocalizedStrings.close_button_a11y)
            }
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            CloseButton(action: {})
        }
    }
}
