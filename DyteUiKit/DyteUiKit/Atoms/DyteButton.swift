//
//  DyteButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit


public protocol DyteButtonAppearance: BaseAppearance {
    var style: DyteButton.Style {get set}
    var state: DyteButton.States {get set}
    var backgroundColor: BrandColorToken.Shade {get set}
    var iconBackgroundColorToken: BackgroundColorToken.Shade {get set}
    var titleColor: TextColorToken.Background.Shade {get set}
    var cornerRadius: BorderRadiusToken.RadiusType {get set}
    var borderWidhtType: BorderWidthToken.Width {get set}
    var selectedStateTintColor: TextColorToken.Background.Shade {get set}
    var normalStateTintColor: TextColorToken.Background.Shade {get set}
    var acitivityInidicatorColor: TextColorToken.Background.Shade {get set}
}

protocol DyteButtonApplyStyle {
    func applyStyle(style: DyteButton.Style)
}

protocol DyteButtonApplyStates {
    func applyState(state: DyteButton.States)
}

public class DyteButtonAppearanceModel : DyteButtonAppearance {
    public var desingLibrary: DyteDesignTokens
    public  var selectedStateTintColor: TextColorToken.Background.Shade
    public var normalStateTintColor: TextColorToken.Background.Shade
    
    public required init(designLibrary: DyteDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        backgroundColor = desingLibrary.color.brand.shade500
        titleColor = desingLibrary.color.textColor.onBackground.shade1000
        selectedStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        normalStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        iconBackgroundColorToken = designLibrary.color.background.shade900
        acitivityInidicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
    public var style: DyteButton.Style = .solid
    public var state: DyteButton.States = .active
    public var backgroundColor: BrandColorToken.Shade
    public var iconBackgroundColorToken: BackgroundColorToken.Shade
    public var acitivityInidicatorColor: TextColorToken.Background.Shade
    public var titleColor: TextColorToken.Background.Shade
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var borderWidhtType: BorderWidthToken.Width = .thin
}

class BaseIndicatorView: UIView {

    let indicatorView: UIActivityIndicatorView = {
        let inidicator = UIActivityIndicatorView(style: .medium)
        inidicator.hidesWhenStopped = true
        return inidicator
    }()
    
    static func createIndicatorView() -> BaseIndicatorView {
        let baseView = BaseIndicatorView()
        baseView.addSubview(baseView.indicatorView)
        baseView.indicatorView.set(.centerView(baseView))
        return baseView
     }
    override var isHidden: Bool {
           get {
               super.isHidden
           }
           set {
               super.isHidden = newValue
               if newValue == true {
                   self.indicatorView.stopAnimating()
               }
           }
       }
    
}

open class DyteButton: UIButton, BaseAtom {
    var isConstraintAdded: Bool = false
    
    public enum Style {
        case solid
        case line
        case iconLeftLable(icon: DyteImage)
        case iconRightLable(icon: DyteImage)
        case text
        case textIconLeft(icon: DyteImage)
        case textIconRight(icon: DyteImage)
        case iconOnly(icon: DyteImage)
        case splitButton
    }
    
    public enum States
    {
        case active
        case disabled
        case hover
        case focus
        case pressed
    }
    
    public enum Size {
        case small
        case medium
        case large
        
        func width() -> CGFloat {
            switch self {
            case .large:
                return 84
            case .medium:
                return 68
            case .small:
                return 46
            }
        }
        
        func height() -> CGFloat {
            switch self {
            case .large:
                return 40
            case .medium:
                return 32
            case .small:
                return 24
            }
        }
    }
    
    private enum IconPlacementDirection {
        case left
        case right
    }
    private let iconButtonSize = 48.0
    
    
    var style: Style = .solid
    var dyteButtonState: States = .active
    var size: Size
    var borderRadiusType: BorderRadiusToken.RadiusType
    var borderWidhtType: BorderWidthToken.Width
    private var appearance: DyteButtonAppearance
    
    public init(style: Style = .solid, dyteButtonState: States = .active, size: Size = .large, appearance: DyteButtonAppearance = DyteButtonAppearanceModel()) {
        self.style = style
        self.appearance = appearance
        self.size = size
        self.dyteButtonState = dyteButtonState
        self.normalStateTintColor = self.appearance.normalStateTintColor
        self.selectedStateTintColor = self.appearance.selectedStateTintColor
        borderRadiusType = self.appearance.cornerRadius
        borderWidhtType = self.appearance.borderWidhtType
        super.init(frame: .zero)
        createButton(style: style)
        applyStyle(style: style)
        applyWidhtHeightConstraint(style: style)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isLoading = false
    private var baseActivityIndicatorView: BaseIndicatorView?
    private var baseContentView: UIView!
    private var titleTextAtom: DyteText!
    private var iconImageView: UIImageView!
    
    
    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var clickAction:((DyteButton)->Void)?
    public var selectedStateTintColor: UIColor
    public var normalStateTintColor: UIColor

    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.tintColor = self.selectedStateTintColor
            }else {
                self.tintColor = self.normalStateTintColor
            }
        }
    }
    
    
    private func setButtonHeight(constant: CGFloat) {
        if self.heightConstraint != nil {
            heightConstraint?.constant = constant
        } else {
            heightConstraint = self.heightAnchor.constraint(equalToConstant: constant)
        }
        heightConstraint?.isActive = true
    }
    
    
    private func setButtonWidth(constant: CGFloat) {
        if self.widthConstraint != nil {
            widthConstraint?.constant = constant
        } else {
            widthConstraint = self.widthAnchor.constraint(equalToConstant: constant)
        }
        widthConstraint?.isActive = true
    }
    
    func setClickAction(click:@escaping(DyteButton)->Void) {
        self.clickAction = click
        self.addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
    }
    
    @objc  private  func click(button: DyteButton) {
        self.clickAction?(button)
    }
    
    func createButton(style: Style) {
        let baseView = UIView()
        baseView.isUserInteractionEnabled = false
        var useDefaultButton = false
        var stackView: BaseStackView!
        switch style {
        case .iconLeftLable(let icon):
            let result = getLabelAndImageOnlyView(dir: .left)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .textIconLeft(let textIcon):
            let result = getLabelAndImageOnlyView(dir: .left)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .iconRightLable(let icon):
            let result = getLabelAndImageOnlyView(dir: .right)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .textIconRight(let textIcon):
            let result = getLabelAndImageOnlyView(dir: .right)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        default:
            useDefaultButton = true
            print("We are going to use default button except all above defined cases and split button case")
            
        }
        if useDefaultButton == false {
            baseContentView = baseView
            baseContentView.addSubview(stackView)
            addContrainst(style: style, stackView: stackView)
        }
        self.layer.masksToBounds = true
    }
    
    private func addContrainst(style: Style, stackView: UIStackView) {
        self.addSubview(baseContentView)
        baseContentView.set(.fillSuperView(self))
    }
   
    private func getLabelOnlyView() -> (stackView: BaseStackView, title: DyteText) {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space1)
        let title = UIUTility.createLabel(text: "")
        stackView.addArrangedSubviews(title)
        return (stackView, title)
    }
    
    private func getIconOnlyView(image: DyteImage) -> (stackView: BaseStackView, imageView: UIImageView) {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space1)
        let iconView = UIUTility.createImageView(image: image)
        stackView.addArrangedSubviews(iconView)
        return (stackView, iconView)
    }
    
    private func getLabelAndImageOnlyView(dir: IconPlacementDirection = .left) -> (stackView: BaseStackView, title: DyteText , imageView: UIImageView) {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space1)
        let imageView = UIUTility.createImageView(image: DyteImage(image: nil))
        let title = UIUTility.createLabel(text: "")
        if dir == .left {
            stackView.addArrangedSubviews(imageView,title)
        }else if dir == .right {
            stackView.addArrangedSubviews(title,imageView)
        }
        return (stackView: stackView ,title: title,imageView: imageView)
    }
 
}

extension DyteButton: DyteButtonApplyStyle {

    func applyStyle(style: Style) {
        //MARK: You can't apply any style, We want to check first what is the style in which button is created for eg. If button is created in Text style then we can't apply icon style on it. Instead we can apply solid, line and text interchangeably.
        resetContentViewAppearance()
        switch style {
        case .solid:
            self.backgroundColor = self.appearance.backgroundColor
            self.setTitleColor(self.appearance.titleColor, for: .normal)
            self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        case .line:
            self.setTitleColor(self.appearance.backgroundColor, for: .normal)
            self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
            self.layer.borderWidth = self.appearance.desingLibrary.borderSize.getWidth(size: .one, width: borderWidhtType)
            self.layer.borderColor = self.appearance.backgroundColor.cgColor

        case .text:
            self.setTitleColor(self.appearance.desingLibrary.color.textColor.onBrand.shade700, for: .normal)
            break
        case .iconLeftLable(let icon):
            break
        case .iconRightLable(let icon):
            break
        case .textIconLeft(let icon):
            break
        case .textIconRight(let icon):
            break
        case .iconOnly(let icon):
            self.backgroundColor = self.appearance.iconBackgroundColorToken
            self.setImage(icon.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.tintColor = normalStateTintColor
            self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
            break
        case .splitButton:
            break
        }
    }
    
    private func applyWidhtHeightConstraint(style: Style) {
        switch style {
        case .solid:
            self.setButtonHeight(constant: size.height())
        case .line:
            self.setButtonHeight(constant: size.height())
            self.setButtonWidth(constant: size.width())
        case .iconLeftLable(let icon):
            break
        case .iconRightLable(let icon):
            break
        case .text:
            self.setButtonHeight(constant: size.height())
            self.setButtonWidth(constant: size.width())
            break
        case .textIconLeft(let icon):
            break
        case .textIconRight(let icon):
            break
        case .iconOnly(let icon):
            self.setButtonWidth(constant: iconButtonSize)
            self.setButtonHeight(constant: iconButtonSize)
            break
        case .splitButton:
            break
        }
    }
    
    private func setContentViewColor(color: UIColor) {
        baseContentView.backgroundColor = color
        baseContentView.layer.borderColor = color.cgColor
    }
    
    private func resetContentViewAppearance() {
        self.layer.cornerRadius = 0.0
        self.layer.borderWidth = 0.0
        self.layer.borderColor = UIColor.clear.cgColor
        self.backgroundColor = .clear
    }
}

extension DyteButton: DyteButtonApplyStates {

    func applyState(state: States) {
        let currentStyle = style
        if case .solid = currentStyle {
            applyStatesOnSolidStyle(state: state)
        }else if case .line = currentStyle {
            applyStatesOnLineStyle(state: state)
        }else if case .text = currentStyle {
            applyStatesOnTextStyle(state: state)
        }
    }
    
    private  func applyStatesOnSolidStyle(state: States) {
          switch state {
          case.active:
              break
          case .disabled:
              break
          case .focus:
              break
          case .hover:
              break
          case .pressed:
              break

          }
      }
      
    private  func applyStatesOnLineStyle(state: States) {
            switch state {
            case.active:
                break
            case .disabled:
                break
            case .focus:
                break
            case .hover:
                break
            case .pressed:
                break
            }
        }
      
    private  func applyStatesOnTextStyle(state: States) {
            switch state {
            case.active:
                break
            case .disabled:
                break
            case .focus:
                break
            case .hover:
                break
            case .pressed:
                break
            }
    }
    
}

extension DyteButton {
      
    func prepareForReuse() {
         hideActivityIndicator()
    }
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
          isLoading = true
      }
      
      func hideActivityIndicator() {
          if self.baseActivityIndicatorView?.isHidden == false {
              self.baseActivityIndicatorView?.indicatorView.stopAnimating()
              self.baseActivityIndicatorView?.isHidden = true
          }
          self.isUserInteractionEnabled = true
          isLoading = false
      }
}
