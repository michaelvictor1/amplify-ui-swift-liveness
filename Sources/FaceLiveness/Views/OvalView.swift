//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// The face guide: an opaque white overlay with the oval cut out, covering the whole view.
///
/// It works out where the camera preview sits from its own bounds each time it lays out, so it
/// stays aligned with the preview as its superview resizes. It renders with shape layers rather
/// than drawing a bitmap, so resizing doesn't reallocate a screen-sized backing store.
class OvalView: UIView {
    /// The oval, relative to the camera preview's origin.
    var ovalFrame: CGRect
    /// The cutout currently drawn, in this view's coordinates.
    private(set) var cutoutInView: CGRect?
    private var growing = false

    /// Soft drop shadow of the hole only — not the page edge.
    private let holeShadowLayer = CAShapeLayer()

    override class var layerClass: AnyClass { CAShapeLayer.self }

    private var overlayLayer: CAShapeLayer {
        layer as! CAShapeLayer
    }

    init(frame: CGRect, ovalFrame: CGRect) {
        self.ovalFrame = ovalFrame
        super.init(frame: frame)
        backgroundColor = .clear

        overlayLayer.fillColor = UIColor.white.cgColor
        overlayLayer.fillRule = .evenOdd
        overlayLayer.masksToBounds = false

        // Vector `shadow.md` — `color.gray.900` at 0.10, 4pt down, 8pt blur.
        holeShadowLayer.fillColor = UIColor.clear.cgColor
        holeShadowLayer.shadowColor = UIColor(
            red: 16 / 255,
            green: 24 / 255,
            blue: 40 / 255,
            alpha: 1
        ).cgColor
        holeShadowLayer.shadowOpacity = 0.10
        holeShadowLayer.shadowRadius = 8
        holeShadowLayer.shadowOffset = CGSize(width: 0, height: 4)
        layer.addSublayer(holeShadowLayer)
    }

    /// ``ovalFrame`` in this view's coordinates, for where the preview sits at the view's current
    /// size.
    var ovalFrameInView: CGRect {
        let previewOrigin = LivenessPreviewGeometry.previewRect(fittingIn: bounds.size).origin
        return ovalFrame.offsetBy(dx: previewOrigin.x, dy: previewOrigin.y)
    }

    /// Draws `rect` with no animation. `rect` is in this view's coordinates.
    func showCutout(_ rect: CGRect) {
        cutoutInView = rect
        apply(rect, animatedFrom: nil)
    }

    /// Grows the cutout from `start` to `end`. Both rects are in this view's coordinates.
    /// Face matching does not read this path — it uses the final oval rect.
    func growCutout(from start: CGRect, to end: CGRect) {
        cutoutInView = end
        guard start.width > 1, !nearlyEqual(start, end) else {
            apply(end, animatedFrom: nil)
            return
        }
        growing = true
        apply(end, animatedFrom: start)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !growing, let rect = cutoutInView, rect.width > 1 else { return }
        apply(rect, animatedFrom: nil)
    }

    private func apply(_ rect: CGRect, animatedFrom start: CGRect?) {
        let endOval = UIBezierPath(ovalIn: rect)
        let endOverlay = UIBezierPath(rect: bounds)
        endOverlay.append(endOval)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.path = endOverlay.cgPath
        holeShadowLayer.frame = bounds
        holeShadowLayer.shadowPath = endOval.cgPath
        CATransaction.commit()

        guard let start else { return }
        let startOval = UIBezierPath(ovalIn: start)
        let startOverlay = UIBezierPath(rect: bounds)
        startOverlay.append(startOval)

        let grow = CABasicAnimation(keyPath: "path")
        grow.duration = 0.45
        grow.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        grow.fromValue = startOverlay.cgPath
        grow.toValue = endOverlay.cgPath

        let shadowGrow = CABasicAnimation(keyPath: "shadowPath")
        shadowGrow.duration = grow.duration
        shadowGrow.timingFunction = grow.timingFunction
        shadowGrow.fromValue = startOval.cgPath
        shadowGrow.toValue = endOval.cgPath

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.growing = false
        }
        overlayLayer.add(grow, forKey: "grow")
        holeShadowLayer.add(shadowGrow, forKey: "grow")
        CATransaction.commit()
    }

    private func nearlyEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 1
            && abs(a.minY - b.minY) < 1
            && abs(a.width - b.width) < 1
            && abs(a.height - b.height) < 1
    }

    required init?(coder: NSCoder) { nil }
}
