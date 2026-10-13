//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Where the camera image sits on screen. The preview layer, the oval, and face landmark
/// normalization all derive from the rect computed here, matching the SwiftUI overlay's
/// `.aspectRatio(3/4, contentMode: .fit)`.
enum LivenessPreviewGeometry {
    /// Width / height of the camera image.
    static let previewAspectRatio: CGFloat = 3.0 / 4.0

    /// The largest centered 3:4 rect inside `viewport`; `.zero` if `viewport` is empty.
    static func previewRect(fittingIn viewport: CGSize) -> CGRect {
        guard viewport.width > 0, viewport.height > 0 else { return .zero }

        let width = min(viewport.width, viewport.height * previewAspectRatio)
        let height = width / previewAspectRatio

        return CGRect(
            x: (viewport.width - width) / 2,
            y: (viewport.height - height) / 2,
            width: width,
            height: height
        )
    }

    /// The instruction's inset from the top of the preview: `inset`, or more when the preview
    /// starts behind the close button (as on iPads close to 3:4), so the instruction sits
    /// below it. Both positions are in the same coordinate space.
    static func instructionTopInset(
        _ inset: CGFloat,
        previewMinY: CGFloat,
        controlsMaxY: CGFloat
    ) -> CGFloat {
        max(inset, controlsMaxY - previewMinY)
    }

    /// The band the face-fit instruction occupies while the oval is up. `top` and `height` are
    /// relative to the preview. The band ends `gap` above `ovalTop`. It starts at
    /// `buttonClearance` unless that would cross the oval, in which case it ends above the oval
    /// and the instruction grows upward.
    static func instructionBandAboveOval(
        ovalTop: CGFloat,
        gap: CGFloat,
        buttonClearance: CGFloat
    ) -> (top: CGFloat, height: CGFloat) {
        let bottom = ovalTop - gap
        let top = min(buttonClearance, bottom)
        return (top, max(0, bottom - top))
    }

    /// Scales the service's oval from video coordinates to a preview `previewWidth` wide. The
    /// result is relative to the preview's origin.
    static func ovalRect(
        forVideoOval videoOval: CGRect,
        videoSize: CGSize,
        previewWidth: CGFloat
    ) -> CGRect {
        guard videoSize.width > 0 else { return .zero }

        let scaleRatio = previewWidth / videoSize.width

        return CGRect(
            x: videoOval.minX * scaleRatio,
            y: videoOval.minY * scaleRatio,
            width: videoOval.width * scaleRatio,
            height: videoOval.height * scaleRatio
        )
    }
}
