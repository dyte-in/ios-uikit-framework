//
//  DyteTopbar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/12/22.
//

import UIKit
import DyteiOSCore

open class DyteNavigationBar:UIView {
    
    private var previousButtonClick: ((DyteControlBarButton)->Void)?
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    let backgroundColorValue = DesignLibrary.shared.color.background.shade700

    public let title: DyteText = {
        return UIUTility.createLabel()
    }()
    
    public let leftButton: DyteControlBarButton = {
        let button = DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_cross")),  appearance: AppTheme.shared.controlBarButtonAppearance)
        return button
    }()
    
    init(title: String) {
        self.title.text = title
        super.init(frame: .zero)
        self.backgroundColor = backgroundColorValue
        createSubViews()

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func createSubViews() {
       self.addSubview(title)
       self.addSubview(leftButton)
       leftButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
       
       leftButton.set(.centerY(self),
                        .top(self, tokenSpace.space1, .greaterThanOrEqual),
                        .leading(self, tokenSpace.space3))
       title.set(.sameTopBottom(self, tokenSpace.space1, .greaterThanOrEqual),
                 .centerY(leftButton),
                 .centerX(self),
                 .trailing(self, tokenSpace.space4, .greaterThanOrEqual),
                 .after(leftButton, tokenSpace.space2, .greaterThanOrEqual))
       
       leftButton.backgroundColor = self.backgroundColor
    }
    
    public  func setClicks(previousButton:@escaping(DyteControlBarButton)->Void) {
        self.previousButtonClick = previousButton
    }
    
    @objc private func clickPrevious(button: DyteControlBarButton) {
        self.previousButtonClick?(button)
     }
     
}




