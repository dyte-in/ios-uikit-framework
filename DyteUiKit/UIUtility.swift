//
//  UIUtility.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit


struct UIUTility {
    
    static func createLabel(text: String? = nil, alignment: NSTextAlignment = .center) -> DyteText {
        let label = DyteText()
        label.textAlignment = alignment
        label.text = text
        return label
    }
    
    static func wrapped(view: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        return wrapper
    }

    static func createButton(text: String) -> DyteButton {
        let button = DyteButton(style: .solid, dyteButtonState: .active, appearance: AppTheme.shared.buttonAppearance)
        button.setTitle("  \(text)  ", for: .normal)
        return button
    }

    static func createStackView(axis: NSLayoutConstraint.Axis, distribution: UIStackView.Distribution = .fill, spacing: CGFloat) -> BaseStackView {
        let stackView = BaseStackView()
        stackView.axis = axis
        stackView.distribution = distribution
        stackView.spacing = spacing
        return stackView
    }
    
    static func createImageView(image: DyteImage?, contentMode: UIView.ContentMode = .scaleAspectFit) -> BaseImageView {
        
        let imageView = BaseImageView()
        imageView.setImage(image: image)
        imageView.contentMode = contentMode
        return imageView
    }
    
    static func displayAlert(defaultActionTitle: String? = "OK", alertTitle: String, message: String) {

        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: defaultActionTitle, style: .default, handler: nil)
        alertController.addAction(defaultAction)

        guard var topController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("keyWindow has no rootViewController")
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(alertController, animated: true, completion: nil)
    }
}