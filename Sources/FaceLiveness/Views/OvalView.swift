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

    private let outlineLayer = CAShapeLayer()
    private let outlineMask = CAShapeLayer()

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

        // A 4pt outline whose inner half is cut away with the oval
        outlineLayer.fillColor = nil
        outlineLayer.strokeColor = UIColor.hex("#AEB3B7").cgColor
        outlineLayer.lineWidth = 4
        outlineMask.fillColor = UIColor.black.cgColor
        outlineMask.fillRule = .evenOdd
        outlineLayer.mask = outlineMask
        layer.addSublayer(outlineLayer)
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
        outlineLayer.frame = bounds
        outlineLayer.path = endOval.cgPath
        outlineMask.frame = bounds
        outlineMask.path = endOverlay.cgPath
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

        let stroke = CABasicAnimation(keyPath: "path")
        stroke.duration = grow.duration
        stroke.timingFunction = grow.timingFunction
        stroke.fromValue = startOval.cgPath
        stroke.toValue = endOval.cgPath

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.growing = false
        }
        overlayLayer.add(grow, forKey: "grow")
        outlineMask.add(grow, forKey: "grow")
        outlineLayer.add(stroke, forKey: "grow")
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
