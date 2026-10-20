//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// Shown while the session starts, before the explainer. Same large gray
/// spinner as the verifying cover, with no line beside it.
struct LoadingPageView: View {
    var body: some View {
        LivenessSpinner()
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LocalizedStrings.challenge_connecting)
    }
}

/// `UIActivityIndicatorView` large, `text.tertiary`. Matches `beginVerifyingCover`.
private struct LivenessSpinner: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .hex("#667085")
        spinner.startAnimating()
        return spinner
    }

    func updateUIView(_ spinner: UIActivityIndicatorView, context: Context) {}
}

struct LoadingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPageView()
    }
}
