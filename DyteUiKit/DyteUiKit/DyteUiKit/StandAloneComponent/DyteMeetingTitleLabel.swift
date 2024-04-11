//
//  DyteMeetingTitle.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public class DyteMeetingTitleLabel: DyteLabel {
    private let meeting: DyteMobileClient
    
    public init(meeting: DyteMobileClient, appearance: DyteTextAppearance = AppTheme.shared.meetingTitleAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.text = self.meeting.meta.meetingTitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
