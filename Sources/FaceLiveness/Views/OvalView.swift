//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// The face guide: the onboarding gradient with the oval cut out, covering the whole view.
///
/// Light is gray.300 → white. Dark is black → gray.800. Top to bottom, same as
/// `OnboardingBackground`. It works out where the camera preview sits from its own bounds
/// each time it lays out, so it stays aligned with the preview as its superview resizes.
class OvalView: UIView {
    /// The oval, relative to the camera preview's origin.
    let ovalFrame: CGRect

    private let gradientLayer = CAGradientLayer()
    private let gradientMask = CAShapeLayer()
    private let outlineLayer = CAShapeLayer()
    private let outlineMask = CAShapeLayer()

    init(frame: CGRect, ovalFrame: CGRect) {
        self.ovalFrame = ovalFrame
        super.init(frame: frame)
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientMask.fillColor = UIColor.black.cgColor
        gradientMask.fillRule = .evenOdd
        gradientLayer.mask = gradientMask
        layer.addSublayer(gradientLayer)

        // A 4pt outline whose inner half is cut away with the oval
        outlineLayer.fillColor = nil
        outlineLayer.strokeColor = UIColor.hex("#AEB3B7").cgColor
        outlineLayer.lineWidth = 4
        outlineMask.fillColor = UIColor.black.cgColor
        outlineMask.fillRule = .evenOdd
        outlineLayer.mask = outlineMask
        layer.addSublayer(outlineLayer)

        applyGradientColors()
    }

    /// ``ovalFrame`` in this view's coordinates, for where the preview sits at the view's current
    /// size.
    var ovalFrameInView: CGRect {
        let previewOrigin = LivenessPreviewGeometry.previewRect(fittingIn: bounds.size).origin
        return ovalFrame.offsetBy(dx: previewOrigin.x, dy: previewOrigin.y)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let oval = UIBezierPath(ovalIn: ovalFrameInView)
        let overlay = UIBezierPath(rect: bounds)
        overlay.append(oval)

        // resizes should move the guide, not animate it
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        gradientMask.frame = bounds
        gradientMask.path = overlay.cgPath
        outlineLayer.frame = bounds
        outlineLayer.path = oval.cgPath
        outlineMask.frame = bounds
        outlineMask.path = overlay.cgPath
        applyGradientColors()
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyGradientColors()
    }

    /// OnboardingBackground: light gray.300 → white, dark black → gray.800, top to bottom.
    private func applyGradientColors() {
        let top: UIColor
        let bottom: UIColor
        if traitCollection.userInterfaceStyle == .dark {
            top = .hex("#000000")
            bottom = .hex("#1D2939")
        } else {
            top = .hex("#D0D5DD")
            bottom = .hex("#FFFFFF")
        }
        gradientLayer.colors = [top.cgColor, bottom.cgColor]
    }

    required init?(coder: NSCoder) { nil }
}
