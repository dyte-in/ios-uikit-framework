//
//  DyteText.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public protocol DyteTextAppearance: BaseAppearance {
    var textColor: TextColorToken.Background.Shade {get set}
    var font: UIFont {get set}
}

public class DyteTextAppearanceModel: DyteTextAppearance {
    public var textColor: TextColorToken.Background.Shade
    
    public var font: UIFont
    
    public var desingLibrary: DyteDesignTokens
    
    public required init(designLibrary: DyteDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        self.textColor = designLibrary.color.textColor.onBackground.shade1000
        self.font = UIFont.systemFont(ofSize: 16)
    }
}


public class DyteLabel: UILabel {
    public init(appearance: DyteTextAppearance = DyteTextAppearanceModel()) {
        super.init(frame: .zero)
        self.textColor = appearance.textColor
        self.font = appearance.font
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTextWhenInsideStackView(text: String?) {
        if let text = text, text.count > 0 {
            self.isHidden =  false
            self.text = text
        }else {
            self.isHidden = true
        }
    }
    
}
