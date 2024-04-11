//
//  DyteTopbar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/12/22.
//

import UIKit
import DyteiOSCore

open class DyteNavigationBar: UIView {
    
    private var previousButtonClick: ((DyteControlBarButton)->Void)?
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    let backgroundColorValue = DesignLibrary.shared.color.background.shade900

    public let titleLabel: DyteLabel = {
        return DyteUIUTility.createLabel()
    }()
    
    public let leftButton: DyteControlBarButton = {
        let button = DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_cross")),  appearance: AppTheme.shared.controlBarButtonAppearance)
        button.accessibilityIdentifier = "Cross_Button"
        return button
    }()
    
    public  init(title: String) {
        self.titleLabel.text = title
        super.init(frame: .zero)
        self.backgroundColor = backgroundColorValue
        createSubViews()

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func createSubViews() {
       self.addSubview(titleLabel)
       self.addSubview(leftButton)
       leftButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
       
       leftButton.set(.centerY(self),
                        .top(self, tokenSpace.space1, .greaterThanOrEqual),
                        .leading(self, tokenSpace.space3))
       titleLabel.set(.sameTopBottom(self, tokenSpace.space1, .greaterThanOrEqual),
                 .centerY(leftButton),
                 .centerX(self),
                 .trailing(self, tokenSpace.space4, .greaterThanOrEqual),
                 .after(leftButton, tokenSpace.space2, .greaterThanOrEqual))
       
       leftButton.backgroundColor = self.backgroundColor
    }
    
    public func setBackButtonClick(callBack: @escaping(DyteControlBarButton)->Void) {
        self.previousButtonClick = callBack
    }
    
    @objc private func clickPrevious(button: DyteControlBarButton) {
        self.previousButtonClick?(button)
     }
     
}




