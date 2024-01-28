//
//  DyteMeetingControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public protocol DyteMeetingControlBarDataSource : AnyObject {
    func getMicControlBarButton(for meeting: DyteMobileClient) ->  DyteControlBarButton?
    func getVideoControlBarButton(for meeting: DyteMobileClient) ->  DyteControlBarButton?
}


open class DyteMeetingControlBar: DyteControlBar {
    
   public weak var dataSource: DyteMeetingControlBarDataSource? {
        didSet {
            if dataSource != nil {
                addButtons(meeting: self.meeting)
            }
        }
    }
    
    private let meeting: DyteMobileClient
    
   public override init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, appearance: appearance, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
       addButtons(meeting: meeting)
    }
    
    private func addButtons(meeting: DyteMobileClient) {
        var buttons = [DyteControlBarButton]()
        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = self.dataSource?.getMicControlBarButton(for: meeting) ?? DyteAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }
        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = self.dataSource?.getVideoControlBarButton(for: meeting) ?? DyteVideoButtonControlBar(mobileClient: meeting)
            buttons.append(videoButton)
        }
        if buttons.count > 0 {
            self.setButtons(buttons)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

