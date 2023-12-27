//
//  UIViewExtension.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 07/12/22.
//

import UIKit

let toastTag = 5555

extension UIViewController{
    var isOnScreen: Bool{
        return self.isViewLoaded && view.window != nil
    }
}

extension UIView {
    func wrapperView() -> UIView {
        let view = UIView()
        view.addSubview(self)
        return view
    }
    
    func blink() {
        self.alpha = 0.2
        UIView.animate(withDuration: 1, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: {self.alpha = 1.0}, completion: nil)
    }
    
    func stopBlink() {
        self.layer.removeAllAnimations()
    }
    
    func getSubviewsOf<T : UIView>(view:UIView) -> [T] {
        var subviews = [T]()
        
        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]
            
            if let subview = subview as? T {
                subviews.append(subview)
            }
        }
        
        return subviews
    }
    
    internal func addSubViews(_ views: UIView...) {
        for view in views {
            self.addSubview(view)
        }
    }
}

// MARK: Add Toast method function in UIView Extension so can use in whole project.
extension UIView {
    func removeToast() {
        self.viewWithTag(toastTag)?.removeFromSuperview()
    }
    
    
    func showToast(toastMessage: String, duration: CGFloat, uiBlocker: Bool = true) {
        DispatchQueue.main.async {
            // View to blur bg and stopping user interaction
            self.removeToast()
            let toastView = self.createToastView(toastMessage: toastMessage, duration: duration, uiBlocker: uiBlocker)
            toastView.tag = toastTag
            self.addSubview(toastView)
        }
    }
    
    private func createToastView(toastMessage: String, duration: CGFloat, uiBlocker: Bool) -> UIView {
        let bgView = UIView(frame: self.frame)
        bgView.backgroundColor = UIColor(red: CGFloat(255.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(255.0/255.0), alpha: CGFloat(0.1))
        
        // Label For showing toast text
        let lblMessage = UILabel()
        lblMessage.numberOfLines = 0
        lblMessage.lineBreakMode = .byWordWrapping
        lblMessage.textColor = .white
        lblMessage.backgroundColor =  UIColor(red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.8))
        lblMessage.textAlignment = .center
        lblMessage.font = UIFont.init(name: "Helvetica Neue", size: 17)
        lblMessage.text = toastMessage
        
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        
        // calculating toast label frame as per message content
        let maxSizeTitle: CGSize = CGSize(width: self.bounds.size.width-16, height: self.bounds.size.height)
        var expectedSizeTitle: CGSize = lblMessage.sizeThatFits(maxSizeTitle)
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeTitle = CGSize(width: maxSizeTitle.width.getMinimum(value2: expectedSizeTitle.width), height: maxSizeTitle.height.getMinimum(value2: expectedSizeTitle.height))
        DispatchQueue.main.async {
            lblMessage.frame = CGRect(x:((self.bounds.size.width)/2) - ((expectedSizeTitle.width+16)/2), y: (self.bounds.size.height/2) - ((expectedSizeTitle.height+16)/2), width: expectedSizeTitle.width+16, height: expectedSizeTitle.height+16)
        }
        
        lblMessage.layer.cornerRadius = 8
        lblMessage.layer.masksToBounds = true
        lblMessage.padding = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        bgView.addSubview(lblMessage)
        if duration >= 0 {
            UIView.animate(withDuration: 2.5, delay: TimeInterval(duration)) {
                lblMessage.alpha = 0
                bgView.alpha = 0
            } completion: { finish in
                bgView.removeFromSuperview()
            }
        }
        bgView.isUserInteractionEnabled = uiBlocker
        return bgView
    }
    
}

extension CGFloat {
    func getMinimum(value2: CGFloat) -> CGFloat {
        if self < value2 {
            return self
        } else
        {
            return value2
        }
    }
}

// MARK: Extension on UILabel for adding insets - for adding padding in top, bottom, right, left.
extension UILabel {
    private struct AssociatedKeys {
        static var padding = UIEdgeInsets()
    }
    
    var padding: UIEdgeInsets? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.padding) as? UIEdgeInsets
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.padding, newValue as UIEdgeInsets?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    override open func draw(_ rect: CGRect) {
        if let insets = padding {
            self.drawText(in: rect.inset(by: insets))
        } else {
            self.drawText(in: rect)
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            if let insets = padding {
                contentSize.height += insets.top + insets.bottom
                contentSize.width += insets.left + insets.right
            }
            return contentSize
        }
    }
}

extension UIStackView {
    
    func addArrangedSubviews(_ views: UIView...) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }
    
    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

extension UIViewController {
    
    var isModal: Bool {
        
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController
        
        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}

@nonobjc extension UIViewController {
    
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        DispatchQueue.main.async {
            if let frame = frame {
                child.view.frame = frame
            }
            self.view.addSubview(child.view)
            child.didMove(toParent: self)
        }
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UITableViewCell: ReusableObject {}

extension UISearchBar {
    
    func changeText(color: UIColor) {
        if let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField,
           let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView {
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = color
            textFieldInsideSearchBar.textColor = color
        }
        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: color]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
    }
}

extension Bundle {
    static let resources: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
             let bundle = Bundle(for:ImageProvider.self)
        if let bundlePath = bundle.path(forResource: "DyteUiKit", ofType: "bundle") {
            return Bundle(path:bundlePath)!
        }
          return bundle
        #endif
    }()
}

extension UIViewController {
    func isLandscape(size: CGSize) -> Bool {
        return size.width > size.height
    }
}

extension UIScreen {
   static var deviceOrientation:UIDeviceOrientation {
        switch UIApplication.shared.statusBarOrientation {
            case .portrait:
               return .portrait
            case .portraitUpsideDown:
               return .portraitUpsideDown
            case .landscapeLeft:
              return .landscapeLeft

            case .landscapeRight:
            return .landscapeRight

            case .unknown:
            return .unknown

         }
    }
    
    static func isLandscape() -> Bool {
        if UIScreen.deviceOrientation == .landscapeLeft || UIScreen.deviceOrientation == .landscapeRight {
            return true
        }
        return false
    }
}

