//
//  DytePeerView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 12/12/22.
//

import Foundation


protocol DytePeerViewDesignDependency: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade {get}
    var cornerRadius: BorderRadiusToken.RadiusType {get}
}

class DytePeerViewViewModel: DytePeerViewDesignDependency {
    public var desingLibrary: DesignTokens
    var backgroundColor: BackgroundColorToken.Shade
    var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    
    required public init(designLibrary: DesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        backgroundColor = designLibrary.color.background.video
    }
}

public  class DytePeerView: BaseView {
    private let appearance: DytePeerViewDesignDependency

    init(frame: CGRect, appearance: DytePeerViewDesignDependency = DytePeerViewViewModel()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.backgroundColor = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .two, radius: self.appearance.cornerRadius)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
