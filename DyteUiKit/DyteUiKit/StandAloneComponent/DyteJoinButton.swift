//
//  DyteJoinButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 08/02/23.
//

import UIKit
import DyteiOSCore

open class DyteJoinButton: DyteButton {
    
    lazy var dyteSelfListner: DyteEventSelfListner = {
        return DyteEventSelfListner(mobileClient: self.meeting)
    }()
    
    let completion: ((DyteJoinButton,Bool)->Void)?
    private let meeting: DyteMobileClient
    
    public init(meeting: DyteMobileClient, onClick:((DyteJoinButton, Bool)->Void)? = nil, appearance: DyteButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        self.completion = onClick
        super.init(appearance: appearance)
        self.setTitle("  Join  ", for: .normal)
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
    }

    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func onClick(button: DyteJoinButton) {
        button.showActivityIndicator()
        self.dyteSelfListner.joinMeeting { [weak self] success in
            guard let self = self else {return}
            button.hideActivityIndicator()
            self.completion?(button,success)
        }
    }
}
