//
//  ScreenShareTabButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 03/01/23.
//

import UIKit


public class NextPreviousButtonView: UIView {
    public  let previousButton: DyteControlBarButton
    public  let nextButton: DyteControlBarButton
    private let firstLabel: DyteText
    private let secondLabel: DyteText
    private let slashLabel: DyteText
    
    private let tokenBorderRadius = DesignLibrary.shared.borderRadius
    private let tokenSpace = DesignLibrary.shared.space
    private let tokenColor = DesignLibrary.shared.color
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor

    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePaginationView ?? .extrarounded
   
    public var autolayoutModeEnable = true
    
    let autoLayoutImageView: BaseImageView = {
        let imageView = UIUTility.createImageView(image: DyteImage(image: ImageProvider.image(named: "icon_topbar_autolayout")))
        return imageView
    }()
    
   convenience init() {
       self.init(firsButtonImage: DyteImage(image: ImageProvider.image(named: "icon_left_arrow")), secondButtonImage: DyteImage(image: ImageProvider.image(named: "icon_right_arrow")))
    }
    
    init(firsButtonImage: DyteImage, secondButtonImage: DyteImage) {
        self.previousButton = DyteControlBarButton(image: firsButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        self.nextButton = DyteControlBarButton(image: secondButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        self.firstLabel = UIUTility.createLabel()
        self.firstLabel.font = UIFont.systemFont(ofSize: 16)
        self.firstLabel.textColor = tokenTextColorToken.onBackground.shade900
        self.slashLabel = UIUTility.createLabel(text: "/")
        self.slashLabel.font = UIFont.systemFont(ofSize: 16)
        self.slashLabel.textColor = tokenTextColorToken.onBackground.shade600
        self.secondLabel = UIUTility.createLabel()
        self.secondLabel.font = UIFont.systemFont(ofSize: 12)
        self.secondLabel.textColor = tokenTextColorToken.onBackground.shade600
        super.init(frame: .zero)
        createView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createView() {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: 0)
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
        
        let buttonBaseViewPrevious = UIView()
        buttonBaseViewPrevious.addSubview(previousButton)
        previousButton.set(.sameTopBottom(buttonBaseViewPrevious),
                           .trailing(buttonBaseViewPrevious),
                           .leading(buttonBaseViewPrevious))
        let buttonBaseViewNext = UIView()
        buttonBaseViewNext.addSubview(nextButton)
        nextButton.set(.sameTopBottom(buttonBaseViewNext),
                           .trailing(buttonBaseViewNext),
                           .leading(buttonBaseViewNext))
        let titleBaseView = UIView()
        titleBaseView.addSubview(firstLabel)
        titleBaseView.addSubview(slashLabel)
        titleBaseView.addSubview(secondLabel)
        
        firstLabel.set(.sameTopBottom(titleBaseView),
                       .leading(titleBaseView))
        slashLabel.set(.sameTopBottom(titleBaseView),
                       .after(firstLabel),
                       .before(secondLabel))
        secondLabel.set(.sameTopBottom(titleBaseView),
                        .trailing(titleBaseView))
        titleBaseView.addSubview(autoLayoutImageView)
        autoLayoutImageView.set(.fillSuperView(titleBaseView))
        
        stackView.addArrangedSubviews(buttonBaseViewPrevious,titleBaseView,buttonBaseViewNext)
        self.backgroundColor = tokenColor.background.shade900
        autoLayoutImageView.backgroundColor = self.backgroundColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = tokenBorderRadius.getRadius(size: .two, radius: borderRadiusType)

    }
    
    func setText(first: String, second: String) {
        self.firstLabel.text = first
        self.secondLabel.text = second
    }
}

public protocol ScreenShareTabButtonDesignDependency: BaseAppearance {
    var selectedStateBackGroundColor:  TextColorToken.Brand.Shade {get}
    var normalStateBackGroundColor: TextColorToken.Background.Shade {get}
    var cornerRadius: BorderRadiusToken.RadiusType {get}
    var titleColor: TextColorToken.Background.Shade {get}
    var acitivityInidicatorColor: TextColorToken.Background.Shade {get}
}


public class ScreenShareTabButtonDesignDependencyModel : ScreenShareTabButtonDesignDependency {
    public var desingLibrary: DyteDesignTokens
    public var selectedStateBackGroundColor: TextColorToken.Brand.Shade
    public var normalStateBackGroundColor: TextColorToken.Background.Shade
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var titleColor: TextColorToken.Background.Shade
    public var acitivityInidicatorColor: TextColorToken.Background.Shade

    public required init(designLibrary: DyteDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        selectedStateBackGroundColor = designLibrary.color.textColor.onBrand.shade500
        normalStateBackGroundColor = designLibrary.color.textColor.onBackground.shade700
        titleColor = designLibrary.color.textColor.onBackground.shade900
        acitivityInidicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
   
}


public class ScreenShareTabButton: UIButton {
    
    private var normalImage: DyteImage?
    private var normalTitle: String
    private var selectedImage: DyteImage?
    private var selectedTitle: String?

    var btnImageView: BaseImageView?
    private var btnTitle: DyteText?
    private var baseActivityIndicatorView: BaseIndicatorView?
    private let appearance: ScreenShareTabButtonDesignDependency
    var index: Int = 0
    
    init(image: DyteImage?, title: String = "", appearance: ScreenShareTabButtonDesignDependency = ScreenShareTabButtonDesignDependencyModel()) {
        self.normalImage = image
        self.appearance = appearance
        self.normalTitle = title
        super.init(frame: .zero)
        self.layer.cornerRadius = appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: appearance.cornerRadius)
        createButton()
        self.backgroundColor = appearance.normalStateBackGroundColor
        self.clipsToBounds = true
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let image = self.selectedImage {
                    self.btnImageView?.setImage(image: image)
                }
                if let title = self.selectedTitle {
                    self.btnTitle?.setTextWhenInsideStackView(text: title)
                }
                self.backgroundColor = appearance.selectedStateBackGroundColor
            }else {
                if let image = self.normalImage {
                    self.btnImageView?.setImage(image: image)
                }
                self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
                self.backgroundColor = appearance.normalStateBackGroundColor
            }
        }
    }
    
    required init?(coder: NSCoder) {
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
        self.btnTitle?.textColor = appearance.titleColor
        self.btnImageView = buttonsComponent.imageView
        self.btnImageView?.tintColor = self.btnTitle?.textColor
        baseView.addSubview(buttonsComponent.stackView)
        buttonsComponent.stackView.set(.top(baseView, tokenSpace.space2, .greaterThanOrEqual),
                                       .centerY(baseView),
                                       .leading(baseView, tokenSpace.space2, .greaterThanOrEqual),
                                       .centerX(baseView))
    }
    
    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: DyteText , imageView: BaseImageView) {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
        let imageView = UIUTility.createImageView(image: self.normalImage)
        let title = UIUTility.createLabel(text: self.normalTitle)
        title.font = UIFont.systemFont(ofSize: 14)
        stackView.addArrangedSubviews(imageView,title)
        return (stackView: stackView ,title: title,imageView: imageView)
    }
}

extension ScreenShareTabButton {
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

extension ScreenShareTabButton {
      
      func showActivityIndicator() {
          if self.baseActivityIndicatorView == nil {
              let baseIndicatorView = BaseIndicatorView.createIndicatorView()
              self.addSubview(baseIndicatorView)
              baseIndicatorView.set(.fillSuperView(self))
              self.baseActivityIndicatorView = baseIndicatorView
          }
          self.baseActivityIndicatorView?.indicatorView.color = appearance.acitivityInidicatorColor
          self.baseActivityIndicatorView?.indicatorView.startAnimating()
          self.baseActivityIndicatorView?.backgroundColor = self.backgroundColor
          self.bringSubviewToFront(self.baseActivityIndicatorView!)
          self.baseActivityIndicatorView?.isHidden = false
      }
      
      func hideActivityIndicator() {
          self.baseActivityIndicatorView?.indicatorView.stopAnimating()
          self.baseActivityIndicatorView?.isHidden = true
      }
}

