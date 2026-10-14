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

    /// Removes the face guide once the check completes (or ends any other way), so "Verifying"
    /// and the final frame show on black.
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


    required init?(coder: NSCoder) { fatalError() }
}

extension _LivenessViewController: FaceLivenessViewControllerPresenter {
    func displaySingleFrame(uiImage: UIImage) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let previewLayer = self.previewLayer else { return }
            let imageView = UIImageView(image: uiImage)
            imageView.frame = previewLayer.frame
            self.view.addSubview(imageView)
            (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
            previewLayer.removeFromSuperlayer()
            self.viewModel.stopRecording()
        }
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
                self.freshnessView.removeFromSuperview()

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
