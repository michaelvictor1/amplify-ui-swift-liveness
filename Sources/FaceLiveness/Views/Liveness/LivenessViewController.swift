//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import Combine
import AVFoundation
import Vision
import Amplify
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

final class _LivenessViewController: UIViewController {
    let viewModel: FaceLivenessDetectionViewModel
    var previewLayer: CALayer?

    var ovalExists = false
    var ovalRect: CGRect?
    var freshness = Freshness()
    let freshnessView = FreshnessView()
    var readyForOval = false

    init(
        viewModel: FaceLivenessDetectionViewModel
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.livenessViewControllerDelegate = self
        viewModel.normalizeFace = { [weak viewModel] face in
            // the same fitted rect the preview and the oval use; lock-guarded, so no main hop
            guard let previewRect = viewModel?.cameraViewRect else { return face }
            return face.normalize(width: previewRect.width, height: previewRect.height)
        }
    }
    
    deinit {
        guard let previewLayer = self.previewLayer else { return }
        previewLayer.removeFromSuperlayer()
        (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
        self.previewLayer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        layoutSubviews()
        setupAVLayer()
        removeFaceGuideWhenCheckEnds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showStartingOvalIfNeeded()
    }

    /// Removes the face guide once the check completes (or ends any other way).
    /// The verifying cover, not the camera, is what shows after that.
    private func removeFaceGuideWhenCheckEnds() {
        faceGuideSubscription = viewModel.$livenessState
            .map(\.isFaceGuideDisplayed)
            .removeDuplicates()
            .filter { !$0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.ovalView?.removeFromSuperview()
                self?.ovalView = nil
            }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGeometryForCurrentViewSize()
    }

    private func layoutSubviews() {
        freshnessView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(freshnessView)
        NSLayoutConstraint.activate([
            freshnessView.topAnchor.constraint(equalTo: view.topAnchor),
            freshnessView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            freshnessView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            freshnessView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        freshnessView.clearColors()
    }

    private func setupAVLayer() {
        guard previewLayer == nil else { return }
        let cameraFrame = LivenessPreviewGeometry.previewRect(fittingIn: view.bounds.size)

        guard let avLayer = viewModel.configureCamera(withinFrame: cameraFrame) else {
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.livenessState
                    .unrecoverableStateEncountered(.missingVideoPermission)
            }
            return
        }

        // `cameraFrame` is already centered; `viewDidLayoutSubviews` takes over on resize
        avLayer.frame = cameraFrame
        self.previewLayer = avLayer
        viewModel.cameraViewRect = cameraFrame

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.layer.insertSublayer(avLayer, at: 0)
            self.view.layoutIfNeeded()

            self.viewModel.startSession()
        }
    }

    /// Re-fits the preview layer and the oval to the view's current size. Skipped while the
    /// fitted rect is unchanged (which also stops the layout pass recursing) or has no area.
    private func updateGeometryForCurrentViewSize() {
        guard let previewLayer = self.previewLayer else { return }

        let cameraFrame = LivenessPreviewGeometry.previewRect(fittingIn: view.bounds.size)
        guard !cameraFrame.isEmpty, cameraFrame != viewModel.cameraViewRect else { return }

        previewLayer.frame = cameraFrame
        viewModel.cameraViewRect = cameraFrame
        viewModel.redrawOvalForCurrentCameraViewRect()
    }

    var runningFreshness = false
    var hasSentClientInformationEvent = false
    var challengeID = UUID().uuidString
    var initialFace: FaceDetection?
    var videoStartTimeStamp: UInt64?
    var faceMatchStartTime: UInt64?
    var freshnessEventsComplete = false
    var videoSentCount = 0
    var hasSentFinalEvent = false
    var hasSentEmptyFinalVideoEvent = false
    var ovalView: OvalView?
    private var faceGuideSubscription: AnyCancellable?
    /// White field shown after the lights, so the final camera frame stays hidden.
    private var verifyingCover: UIView?


    required init?(coder: NSCoder) { fatalError() }
}

extension _LivenessViewController: FaceLivenessViewControllerPresenter {
    func displaySingleFrame(uiImage: UIImage) {
        DispatchQueue.main.async { [weak self] in
            // The still is only a display frame. The video is already finished.
            _ = uiImage
            self?.beginVerifyingCover()
        }
    }

    /// White field and a centered spinner, faded over the last color (or the
    /// live camera, when there were no lights). The final frame is never shown.
    func beginVerifyingCover() {
        let present = { [weak self] in
            guard let self, self.verifyingCover == nil else { return }
            self.viewModel.restoreBrightnessForVerifying?()
            // The color overlay is translucent during the lights. Make it solid
            // so the fade does not show the camera through it.
            self.freshnessView.alpha = 1

            let cover = UIView(frame: self.view.bounds)
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cover.backgroundColor = .white
            cover.alpha = 0
            cover.isAccessibilityElement = true
            cover.accessibilityLabel = LocalizedStrings.challenge_verifying

            let spinner = UIActivityIndicatorView(style: .large)
            // text.tertiary, the same gray as the app's other loaders.
            spinner.color = .hex("#667085")
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            cover.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
            ])

            self.view.addSubview(cover)
            self.verifyingCover = cover
            UIAccessibility.post(
                notification: .announcement,
                argument: LocalizedStrings.challenge_verifying
            )

            let fade: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0.12 : 0.32
            UIView.animate(withDuration: fade, delay: 0, options: [.curveEaseInOut]) {
                cover.alpha = 1
            } completion: { [weak self] _ in
                self?.stopPreview()
            }
        }
        if Thread.isMainThread {
            present()
        } else {
            DispatchQueue.main.async(execute: present)
        }
    }

    /// Stops the camera once the white field is up, so a frozen frame cannot
    /// show through the fade.
    private func stopPreview() {
        guard let previewLayer else { return }
        (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
        previewLayer.removeFromSuperlayer()
        self.previewLayer = nil
        viewModel.stopRecording()
    }

    func displayFreshness(colorSequences: [FaceLivenessSession.DisplayColor]) {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.livenessState.displayingFreshness()
        }
        self.freshness.showColorSequences(
            colorSequences,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height,
            view: self.freshnessView,
            onNewColor: { [weak self] colorEvent in
                self?.viewModel.sendColorDisplayedEvent(colorEvent)
            },
        onComplete: { [weak self] in
            guard let self else { return }
            self.beginVerifyingCover()
            self.viewModel.handleFreshnessComplete()
        }
        )
    }

    func stopFreshness() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.freshness.cancel()
            // Clear the colors but leave the view in the hierarchy so that, if the face
            // returns and re-matches, `displayFreshness(colorSequences:)` can restart the
            // flash on the same view.
            self.freshnessView.clearColors()
        }
    }

    func drawOvalInCanvas(_ ovalRect: CGRect) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let firstServiceOval = !self.ovalExists
            let ovalView = self.installOvalView(ovalFrame: ovalRect)
            ovalView.ovalFrame = ovalRect
            let end = ovalView.ovalFrameInView
            if firstServiceOval {
                let start = ovalView.cutoutInView ?? self.getReadyOvalInView() ?? end
                ovalView.growCutout(from: start, to: end)
            } else {
                ovalView.showCutout(end)
            }

            self.ovalRect = ovalRect
            self.ovalExists = true
        }
    }

    /// Keeps the Center your face oval up so it can grow into the scanning oval.
    private func showStartingOvalIfNeeded() {
        guard ovalView == nil, let start = getReadyOvalInView() else { return }
        let ovalView = installOvalView(ovalFrame: .zero)
        ovalView.showCutout(start)
    }

    private func installOvalView(ovalFrame: CGRect) -> OvalView {
        if let ovalView {
            ovalView.frame = view.bounds
            return ovalView
        }
        let ovalView = OvalView(frame: view.bounds, ovalFrame: ovalFrame)
        ovalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.ovalView = ovalView
        view.insertSubview(ovalView, belowSubview: freshnessView)
        return ovalView
    }

    /// Center-your-face ellipse in this view's coordinates.
    private func getReadyOvalInView() -> CGRect? {
        let global = viewModel.getReadyOvalInGlobal
        guard global.width > 1, view.window != nil else { return nil }
        let local = view.convert(global, from: nil)
        guard view.bounds.intersects(local) else { return nil }
        return local
    }
    
    func completeNoLightCheck() {
        self.viewModel.completeNoLightCheck()
    }
}
