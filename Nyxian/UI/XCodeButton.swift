/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import SwiftUI
import UIKit

class XCodeButton {
    static var shared: XCButton = XCButton(frame: CGRect(x: 0, y: 0, width: 56 + 8, height: 56 + 8))
    
    static func updateProgress(progress: Double) {
        DispatchQueue.main.async {
            self.shared.XCProgressView!.setProgress(progress)
        }
    }
    
    static func incrementProgress(progress: Double) {
        DispatchQueue.main.async {
            self.shared.XCProgressView!.setProgress(shared.XCProgressView!.progress + progress)
        }
    }
    
    static func resetProgress() {
        DispatchQueue.main.async {
            shared.XCProgressView!.resetProgress()
        }
    }
    
    static func getProgress() -> Double {
        return DispatchQueue.main.sync {
            return Double(shared.XCProgressView!.progress)
        }
    }
    
    static func updateProgressIncrement(progress: Double) {
        DispatchQueue.main.async {
            if progress > shared.XCProgressView!.progress {
                shared.XCProgressView!.setProgress(progress)
            }
        }
    }
    
    static func switchImage(systemName: String, animated: Bool = true, duration: Double = 0.6) {
        DispatchQueue.main.async {
            guard let imageView = XCodeButton.shared.XCImageView else { return }
            
            if animated {
                let currentAlpha = imageView.layer.presentation()?.opacity ?? Float(imageView.alpha)
                imageView.layer.removeAllAnimations()
                imageView.alpha = CGFloat(currentAlpha)
                
                UIView.animate(withDuration: duration / 2, animations: {
                    imageView.alpha = 0.0
                }) { _ in
                    imageView.image = UIImage(systemName: systemName)
                    UIView.animate(withDuration: duration / 2) {
                        imageView.alpha = 1.0
                    }
                }
            } else {
                imageView.image = UIImage(systemName: systemName)
            }
        }
    }
    
    static func switchImageSync(systemName: String, animated: Bool = true, duration: Double = 0.6) {
        guard let imageView = XCodeButton.shared.XCImageView else { return }
        
        if animated {
            let currentAlpha = imageView.layer.presentation()?.opacity ?? Float(imageView.alpha)
            imageView.layer.removeAllAnimations()
            imageView.alpha = CGFloat(currentAlpha)
            
            UIView.animate(withDuration: duration / 2, animations: {
                imageView.alpha = 0.0
            }) { _ in
                imageView.image = UIImage(systemName: systemName)
                UIView.animate(withDuration: duration / 2) {
                    imageView.alpha = 1.0
                }
            }
        } else {
            imageView.image = UIImage(systemName: systemName)
        }
    }
}

class ProgressCircleView: UIView {
    var progress: CGFloat = 0 {
        didSet { progressLayer.strokeEnd = progress }
    }

    func setProgress(_ newProgress: CGFloat) {
        guard newProgress > progressLayer.strokeEnd + 0.05 else { return }
        
        let clamped = min(max(newProgress, 0), 1)
        
        let currentStrokeEnd = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentStrokeEnd
        animation.toValue = clamped
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        progressLayer.strokeEnd = clamped
        progressLayer.add(animation, forKey: "strokeEndAnim")
        
        progress = clamped
    }
    
    func resetProgress() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = 0.0
        CATransaction.commit()
        progress = 0.0
    }

    // MARK: - Private
    private let backgroundCircle = CAShapeLayer()
    private let progressLayer    = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundCircle.strokeColor = UITableViewCell.appearance().backgroundColor?.cgColor
        backgroundCircle.fillColor   = UIColor.clear.cgColor
        backgroundCircle.lineWidth   = 2
        backgroundCircle.lineCap     = .butt
        
        progressLayer.strokeColor = UILabel.appearance().textColor.cgColor
        progressLayer.fillColor   = UIColor.clear.cgColor
        progressLayer.lineWidth   = 2
        progressLayer.strokeEnd   = 0
        progressLayer.lineCap     = .round
        
        layer.addSublayer(backgroundCircle)
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = min(bounds.width, bounds.height) / 2 - progressLayer.lineWidth/2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = -CGFloat.pi / 2   // top
        let endAngle   = startAngle + 2 * CGFloat.pi
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)

        backgroundCircle.frame = bounds
        backgroundCircle.path  = path.cgPath

        progressLayer.frame = bounds
        progressLayer.path  = path.cgPath

        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}

class XCButton: UIButton {
    var XCImageView: UIImageView? = nil
    var XCProgressView: ProgressCircleView? = nil
    
    var isTriggered: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.XCProgressView = ProgressCircleView(frame: self.bounds)
        self.XCProgressView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.XCProgressView!)
        
        guard let image = UIImage(systemName: "hammer.fill") else { return }
        self.XCImageView = UIImageView(image: image)
        self.XCImageView!.tintColor = UIColor.label
        self.XCImageView!.contentMode = .scaleAspectFit
        self.XCImageView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.XCImageView!)
        
        NSLayoutConstraint.activate([
            self.XCProgressView!.widthAnchor.constraint(equalToConstant: self.frame.width / 2.2),
            self.XCProgressView!.heightAnchor.constraint(equalTo: self.XCProgressView!.widthAnchor),
            self.XCProgressView!.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.XCProgressView!.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            self.XCImageView!.widthAnchor.constraint(equalTo: self.XCProgressView!.widthAnchor, multiplier: 0.55),
            self.XCImageView!.heightAnchor.constraint(equalTo: self.XCImageView!.widthAnchor),
            self.XCImageView!.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.XCImageView!.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
