//
//  DyteControlBarButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 29/12/22.
//

import UIKit


public protocol DyteControlBarButtonAppearance: BaseAppearance {
    var cornerRadius : BorderRadiusToken.RadiusType {get}
    var selectedStateTintColor: TextColorToken.Background.Shade {get}
    var normalStateTintColor: TextColorToken.Background.Shade {get}
    var acitivityInidicatorColor: TextColorToken.Background.Shade {get}

}

public class DyteControlBarButtonAppearanceModel: DyteControlBarButtonAppearance {
    public var selectedStateTintColor: TextColorToken.Background.Shade
    public var normalStateTintColor: TextColorToken.Background.Shade
    public var acitivityInidicatorColor: TextColorToken.Background.Shade
    public var desingLibrary: DyteDesignTokens
    public var cornerRadius : BorderRadiusToken.RadiusType = .rounded

    public required init(designLibrary: DyteDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        selectedStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        normalStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        acitivityInidicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
}

open class DyteControlBarButton: UIButton {

    private var normalImage: DyteImage
    private var normalTitle: String
    private var selectedImage: DyteImage?
    private var selectedTitle: String?
    public var selectedStateTintColor: UIColor
    public var normalStateTintColor: UIColor

    private var btnImageView: UIImageView?
    var btnTitle: DyteText?
    private var baseActivityIndicatorView: BaseIndicatorView?
    private var previousTitle: String?

    public var notificationBadge = DyteNotificationBadgeView()
    let appearance: DyteControlBarButtonAppearance
    
   public init(image: DyteImage, title: String = "", appearance: DyteControlBarButtonAppearance = DyteControlBarButtonAppearanceModel()) {
        self.appearance = appearance
        self.normalImage = DyteImage.init(image: image.image?.withRenderingMode(.alwaysTemplate), url: image.url)
        self.normalTitle = title
        self.normalStateTintColor = self.appearance.normalStateTintColor
        self.selectedStateTintColor = self.appearance.selectedStateTintColor
        super.init(frame: .zero)
        self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: self.appearance.cornerRadius)
        createButton()
        self.backgroundColor = self.appearance.desingLibrary.color.background.shade900
        self.clipsToBounds = true
    }
    
    public override var isEnabled: Bool {
        didSet {
            if isEnabled == false {
                self.btnImageView?.tintColor = self.appearance.desingLibrary.color.textColor.onBackground.shade600
            }else {
                self.btnImageView?.tintColor = self.appearance.desingLibrary.color.textColor.onBackground.shade1000
            }
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let image = self.selectedImage {
                    self.btnImageView?.image = image.image
                }
                self.btnImageView?.tintColor = self.selectedStateTintColor
                if let title = self.selectedTitle {
                    self.btnTitle?.setTextWhenInsideStackView(text: title)
                }
            }else {
                self.btnImageView?.image = self.normalImage.image
                self.btnImageView?.tintColor = self.normalStateTintColor
                self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   public func setSelected(image: DyteImage? = nil, title: String? = nil) {
        self.selectedImage = DyteImage.init(image: image?.image?.withRenderingMode(.alwaysTemplate), url: image?.url)
        self.selectedTitle = title
        self.isSelected = true
    }
    
    public  func setDefault(image: DyteImage? = nil, title: String? = nil) {
        self.normalImage = DyteImage.init(image: image?.image?.withRenderingMode(.alwaysTemplate), url: image?.url)
        if let title = title {
            self.normalTitle = title
        }
        self.isSelected = false
    }
    
   private func createButton() {
        let baseView = UIView()
        self.addSubview(baseView)
        baseView.set(.fillSuperView(self, dyteSharedTokenSpace.space1))
        baseView.isUserInteractionEnabled = false
        let buttonsComponent = getLabelAndImageOnlyView()
        self.btnTitle = buttonsComponent.title
        self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
        self.btnTitle?.textColor = self.appearance.desingLibrary.color.textColor.onBackground.shade1000
        self.btnImageView = buttonsComponent.imageView
        self.btnImageView?.tintColor = self.appearance.desingLibrary.color.textColor.onBackground.shade1000
        baseView.addSubview(buttonsComponent.stackView)
        buttonsComponent.stackView.set(.top(baseView, 0.0, .greaterThanOrEqual),
                                       .centerY(baseView),
                                       .leading(baseView, 0.0, .greaterThanOrEqual),
                                       .centerX(baseView))
        baseView.addSubview(notificationBadge)
        let height = dyteSharedTokenSpace.space4
        notificationBadge.set(.top(baseView),
                              .trailing(baseView),
                              .height(height),
                              .width(height*2.5, .lessThanOrEqual))
        notificationBadge.layer.cornerRadius = height/2.0
        notificationBadge.layer.masksToBounds = true
        notificationBadge.backgroundColor = dyteSharedTokenColor.brand.shade500
        notificationBadge.isHidden = true
    }
    
    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: DyteText , imageView: UIImageView) {
        let stackView = DyteUIUTility.createStackView(axis: .vertical, spacing: 4)
        let imageView = DyteUIUTility.createImageView(image: self.normalImage)
        let title = DyteUIUTility.createLabel(text: self.normalTitle)
        title.font = UIFont.systemFont(ofSize: 12)
        title.minimumScaleFactor = 0.7
        title.adjustsFontSizeToFitWidth = true
        stackView.addArrangedSubviews(imageView,title)
        return (stackView: stackView ,title: title,imageView: imageView)
    }
    
    func clean() {
        
    }
}

extension DyteControlBarButton {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.alpha = 0.6
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.alpha = 1.0
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.alpha = 1.0
    }
}

extension DyteControlBarButton {
      
    func showActivityIndicator(title: String = "") {
         self.previousTitle = self.btnTitle?.text
          if self.baseActivityIndicatorView == nil {
              let baseIndicatorView = BaseIndicatorView.createIndicatorView()
              self.baseActivityIndicatorView = baseIndicatorView
          }
        self.baseActivityIndicatorView?.removeFromSuperview()
        if title.count >= 0 {
            if let baseActivityIndicatorView = self.baseActivityIndicatorView, let btnImageView = self.btnImageView {
                btnImageView.addSubview(baseActivityIndicatorView)
                baseActivityIndicatorView.set(.fillSuperView(btnImageView))
                baseActivityIndicatorView.isHidden = true
            }
        }else {
            if let baseActivityIndicatorView = self.baseActivityIndicatorView {
                self.addSubview(baseActivityIndicatorView)
                baseActivityIndicatorView.set(.fillSuperView(self))
                baseActivityIndicatorView.isHidden = true
            }
        }
          if self.baseActivityIndicatorView?.isHidden == true {
              self.baseActivityIndicatorView?.indicatorView.color = self.appearance.acitivityInidicatorColor
              self.baseActivityIndicatorView?.indicatorView.startAnimating()
              self.baseActivityIndicatorView?.backgroundColor = self.backgroundColor
              self.bringSubviewToFront(self.baseActivityIndicatorView!)
              self.baseActivityIndicatorView?.isHidden = false
              self.isUserInteractionEnabled = false
              self.btnTitle?.setTextWhenInsideStackView(text: title)
          }
      }
      
      func hideActivityIndicator() {
          self.btnTitle?.setTextWhenInsideStackView(text: self.previousTitle)
          if self.baseActivityIndicatorView?.isHidden == false {
              self.baseActivityIndicatorView?.indicatorView.stopAnimating()
              self.baseActivityIndicatorView?.isHidden = true
              self.isUserInteractionEnabled = true
          }
      }
}


public class DyteControlBarSpacerButton: DyteControlBarButton {
    public init(space:CGSize) {
        super.init(image: DyteImage())
        self.set(.size(space.width, space.height))
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
