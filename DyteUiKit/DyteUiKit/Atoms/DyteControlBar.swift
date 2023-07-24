//
//  DyteTabBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 29/12/22.
//

import UIKit

public protocol DyteTabBarDelegate: AnyObject {
    func didTap(button: DyteControlBarButton, atIndex index:NSInteger)
    func getTabBarHeight() -> CGFloat
}

public protocol DyteControlBarAppearance: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade {get set}
}

public class DyteControlBarAppearanceModel : DyteControlBarAppearance {
    public var desingLibrary: DesignTokens

    public required init(designLibrary: DesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        backgroundColor = desingLibrary.color.background.shade700
    }

    public var backgroundColor: BackgroundColorToken.Shade
}

open class DyteControlBar: UIView {
    
    private struct Constants {
        static let tabBarAnimationDuration: Double = 1.5

    }
    
    private lazy var containerView: UIView = {
       UIView()
    }()
    
    public weak var delegate:DyteTabBarDelegate?
    
    private let tokenSpace = DesignLibrary.shared.space

    public let stackView = UIStackView()
    
    private var appearance: DyteControlBarAppearance

    @objc public static var height:CGFloat {
        get {
            var bottomAdjust:CGFloat = 0.0
            bottomAdjust = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
            return baseHeight + (bottomAdjust == 0.0 ? defaultBottomAdjustForNonNotch : bottomAdjust)
        }
    }
    
    @objc public static var baseHeight: CGFloat = 49.0
    @objc public static var defaultSafeAreaInsetBottomNotch: CGFloat = 34.0
    @objc public static var defaultBottomAdjustForNonNotch: CGFloat = 10.0

    public private(set) var buttons: [DyteControlBarButton] = []
    
    private var selectedButton: DyteControlBarButton? {
        didSet {
            
        }
    }
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        self.setHeight()
    }
    private var heightConstraint: NSLayoutConstraint?
    
    private func setHeight() {
       if let constraint = self.heightConstraint {
           self.removeConstraint(constraint)
       }
        let height = DyteControlBar.baseHeight + (self.safeAreaInsets.bottom == 0 ? DyteControlBar.defaultBottomAdjustForNonNotch : self.safeAreaInsets.bottom)
       self.heightConstraint = self.heightAnchor.constraint(equalToConstant: delegate?.getTabBarHeight() ?? height)
       self.heightConstraint?.isActive = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("initwithcoder not supported")
    }

    public init(delegate: DyteTabBarDelegate?, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.backgroundColor = appearance.backgroundColor
        self.delegate = delegate
        createViews()
    }
    
   private func createViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        createContainerView()
        createStackView()
        layoutViews()
        self.setHeight()
    }
    
    private func createContainerView() {
        addSubview(containerView)
        bringSubviewToFront(containerView)
        self.backgroundColor = appearance.backgroundColor
    }
    
   
    
    private func createStackView() {
        containerView.addSubview(self.stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.clipsToBounds = true
    }
    
   private func layoutViews() {
        stackView.set(.fillSuperView(containerView))
        containerView.set(.sameLeadingTrailing(self, tokenSpace.space4),
                          .top(self, tokenSpace.space2),
                          .bottom(self, tokenSpace.space3))
    }
    
    
    public func setButtons(_ buttons: [DyteControlBarButton]) {
        for button in self.buttons {
            button.superview?.removeFromSuperview()
        }
        self.buttons.removeAll()
        self.buttons = buttons
        
        for button in self.buttons {
            let baseView = BaseView()
            baseView.addSubview(button)
            
            button.set(.top(baseView, 0.0, .greaterThanOrEqual),
                       .centerY(baseView),
                       .centerX(baseView),
                       .leading(baseView, 0.0, .greaterThanOrEqual))
            button.backgroundColor = self.backgroundColor
            stackView.addArrangedSubview(baseView)
        }
    }
    
    
    public func selectButton(at index: Int) {
        if index >= 0 && index < buttons.count {
            selectedButton = buttons[index]
        }
    }
    
    public func getButton(at index: Int) -> DyteControlBarButton? {
        if index >= 0 && index < buttons.count {
            return buttons[index]
        }
        return nil
    }
}


