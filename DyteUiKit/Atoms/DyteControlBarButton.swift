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
    public var desingLibrary: DesignTokens
    public var cornerRadius : BorderRadiusToken.RadiusType = .rounded

    public required init(designLibrary: DesignTokens = DesignLibrary.shared) {
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
    private var btnTitle: DyteText?
    private var baseActivityIndicatorView: BaseIndicatorView?

    public var notificationBadge = UIView ()
    let appearance: DyteControlBarButtonAppearance
    
    init(image: DyteImage, title: String = "", appearance: DyteControlBarButtonAppearance = DyteControlBarButtonAppearanceModel()) {
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
                    self.btnImageView?.tintColor = self.selectedStateTintColor
                }
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
    
    func setSelected(image: DyteImage? = nil, title: String? = nil) {
        self.selectedImage = DyteImage.init(image: image?.image?.withRenderingMode(.alwaysTemplate), url: image?.url)
        self.selectedTitle = title
    }
    
    func createButton() {
        let baseView = UIView()
        self.addSubview(baseView)
        baseView.set(.fillSuperView(self))
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
        let height = tokenSpace.space3
        notificationBadge.set(.top(baseView),
                              .trailing(baseView),
                              .width(height),
                              .height(height))
        notificationBadge.layer.cornerRadius = height/2.0
        notificationBadge.layer.masksToBounds = true
        notificationBadge.backgroundColor = tokenColor.brand.shade500
        notificationBadge.isHidden = true
    }
    
    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: DyteText , imageView: UIImageView) {
        let stackView = UIUTility.createStackView(axis: .vertical, spacing: 4)
        let imageView = UIUTility.createImageView(image: self.normalImage)
        let title = UIUTility.createLabel(text: self.normalTitle)
        title.font = UIFont.systemFont(ofSize: 12)
        stackView.addArrangedSubviews(imageView,title)
        return (stackView: stackView ,title: title,imageView: imageView)
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
      
      func showActivityIndicator() {
          if self.baseActivityIndicatorView == nil {
              let baseIndicatorView = BaseIndicatorView.createIndicatorView()
              self.addSubview(baseIndicatorView)
              baseIndicatorView.set(.fillSuperView(self))
              baseIndicatorView.isHidden = true
              self.baseActivityIndicatorView = baseIndicatorView
          }
          if self.baseActivityIndicatorView?.isHidden == true {
              self.baseActivityIndicatorView?.indicatorView.color = self.appearance.acitivityInidicatorColor
              self.baseActivityIndicatorView?.indicatorView.startAnimating()
              self.baseActivityIndicatorView?.backgroundColor = self.backgroundColor
              self.bringSubviewToFront(self.baseActivityIndicatorView!)
              self.baseActivityIndicatorView?.isHidden = false
              self.isUserInteractionEnabled = false
          }
      }
      
      func hideActivityIndicator() {
          if self.baseActivityIndicatorView?.isHidden == false {
              self.baseActivityIndicatorView?.indicatorView.stopAnimating()
              self.baseActivityIndicatorView?.isHidden = true
              self.isUserInteractionEnabled = true

          }
      }
}

