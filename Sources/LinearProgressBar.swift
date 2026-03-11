//
//  LinearProgressBar.swift
//  LinearProgressBar
//
//  Created by Firdavs Khaydarov on 09/03/18.
//  Copyright © 2018 Firdavs Khaydarov. All rights reserved.
//

import UIKit

public enum LinearProgressBarState {
    case determinate(percentage: CGFloat)
    case indeterminate
}

open class LinearProgressBar: UIView {

    private let firstProgressComponent = CAShapeLayer()
    private let secondProgressComponent = CAShapeLayer()
    private lazy var progressComponents = [firstProgressComponent, secondProgressComponent]

    // Gradient layer sits on top; the two shape layers act as its mask
    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CALayer()

    private(set) var isAnimating = false
    open private(set) var state: LinearProgressBarState = .indeterminate
    var animationDuration: TimeInterval = 2.5

    open var progressBarWidth: CGFloat = 2.0 {
        didSet { updateProgressBarWidth() }
    }

    /// Used as a fallback when `gradientColors` is nil / empty.
    open var progressBarColor: UIColor = .systemBlue {
        didSet { updateProgressBarColor() }
    }

    /// Set two or more colors to enable a gradient.
    /// Set to `nil` (or an empty array) to fall back to `progressBarColor`.
    open var gradientColors: [UIColor]? = [.systemBlue, .systemPurple] {
        didSet { updateGradient() }
    }

    /// Gradient direction: 0 = left→right (default), .pi/2 = top→bottom, etc.
    open var gradientAngle: CGFloat = 0 {
        didSet { updateGradientAngle() }
    }

    open var cornerRadius: CGFloat = 0 {
        didSet { updateCornerRadius() }
    }

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
        prepareLines()
        prepareGradient()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
        prepareLines()
        prepareGradient()
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateLineLayers()
        updateGradientFrame()
    }

    // MARK: - Setup

    private func prepare() {
        clipsToBounds = true
    }

    func prepareLines() {
        progressComponents.forEach {
            $0.fillColor   = UIColor.clear.cgColor
            $0.lineWidth   = progressBarWidth
            $0.strokeColor = UIColor.white.cgColor   // colour is driven by gradient; keep white here
            $0.strokeStart = 0
            $0.strokeEnd   = 0
            maskLayer.addSublayer($0)
        }
    }

    private func prepareGradient() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        updateGradient()

        // The mask layer composite lets both shape layers drive visibility of the gradient
        gradientLayer.mask = maskLayer
        layer.addSublayer(gradientLayer)
    }

    // MARK: - Update helpers

    private func updateLineLayers() {
        frame = CGRect(x: frame.minX, y: frame.minY,
                       width: bounds.width, height: progressBarWidth)

        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: bounds.midY))
        linePath.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))

        progressComponents.forEach {
            $0.path  = linePath.cgPath
            $0.frame = bounds
        }
    }

    private func updateGradientFrame() {
        gradientLayer.frame = bounds
        maskLayer.frame     = bounds
    }

    private func updateGradient() {
        if let colors = gradientColors, colors.count >= 2 {
            gradientLayer.colors = colors.map { $0.cgColor }
        } else {
            // Single-color fallback via a flat gradient
            gradientLayer.colors = [progressBarColor.cgColor, progressBarColor.cgColor]
        }
    }

    private func updateGradientAngle() {
        let x = cos(gradientAngle)
        let y = sin(gradientAngle)
        // Convert unit-circle vector → CAGradientLayer 0…1 coordinate space
        gradientLayer.startPoint = CGPoint(x: (1 - x) / 2, y: (1 + y) / 2)
        gradientLayer.endPoint   = CGPoint(x: (1 + x) / 2, y: (1 - y) / 2)
    }

    private func updateProgressBarColor() {
        // Only matters when gradientColors is not set
        if gradientColors == nil || gradientColors?.isEmpty == true {
            updateGradient()
        }
    }

    private func updateProgressBarWidth() {
        progressComponents.forEach { $0.lineWidth = progressBarWidth }
        updateLineLayers()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
    }

    // MARK: - Animate

    func forceBeginRefreshing() {
        isAnimating = false
        startAnimating()
    }

    open func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        applyProgressAnimations()
    }

    open func stopAnimating(completion: (() -> Void)? = nil) {
        guard isAnimating else { return }
        isAnimating = false
        removeProgressAnimations()
        completion?()
    }

    // MARK: - Animations

    private func applyProgressAnimations() {
        applyFirstComponentAnimations(to: firstProgressComponent)
        applySecondComponentAnimations(to: secondProgressComponent)
    }

    private func applyFirstComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values   = [0, 1]
        strokeEndAnimation.keyTimes = [0, NSNumber(value: 1.2 / animationDuration)]
        strokeEndAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                              CAMediaTimingFunction(name: .easeOut)]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values   = [0, 1.2]
        strokeStartAnimation.keyTimes = [NSNumber(value: 0.25 / animationDuration),
                                         NSNumber(value: 1.8  / animationDuration)]
        strokeStartAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeIn),
                                                CAMediaTimingFunction(name: .easeIn)]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.duration    = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation,   forKey: "firstComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "firstComponentStrokeStart")
    }

    private func applySecondComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values   = [0, 1.1]
        strokeEndAnimation.keyTimes = [NSNumber(value: 1.375 / animationDuration), 1]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values   = [0, 1]
        strokeStartAnimation.keyTimes = [NSNumber(value: 1.825 / animationDuration), 1]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                  CAMediaTimingFunction(name: .easeOut)]
            $0.duration    = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation,   forKey: "secondComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "secondComponentStrokeStart")
    }

    private func removeProgressAnimations() {
        progressComponents.forEach { $0.removeAllAnimations() }
    }
}
