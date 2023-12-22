//
//  DyteJoinButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 08/02/23.
//

import UIKit
import DyteiOSCore

open class DyteJoinButton: DyteButton {
    
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
        let userName = meeting.localUser.name
        if userName.trimmingCharacters(in: .whitespaces).isEmpty || userName == "Join as XYZ" {
            UIUTility.displayAlert(alertTitle: "Error", message: "Name Required")
        } else {
            button.showActivityIndicator()
            self.meeting.joinRoom {[weak self]  in
                   guard let self = self else {return}
                   button.hideActivityIndicator()
                   self.completion?(button,true)
            } onRoomJoinFailed: {
                [weak self]  in
                       guard let self = self else {return}
                       button.hideActivityIndicator()
                       self.completion?(button,false)
            }
        }
    }
}
