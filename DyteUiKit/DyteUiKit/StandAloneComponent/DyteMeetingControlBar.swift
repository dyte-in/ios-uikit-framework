//
//  DyteMeetingControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore


open class DyteMeetingControlBar: DyteControlBar {
    public let moreButton: DyteMoreButtonControlBar
   
    init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), meetingViewModel: MeetingViewModel, settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        let moreButton = DyteMoreButtonControlBar(mobileClient: meeting, presentingViewController: presentingViewController, meetingViewModel: meetingViewModel, settingViewControllerCompletion: settingViewControllerCompletion)
        self.moreButton = moreButton
        super.init(delegate: delegate, appearance: appearance)
        let micButton = DyteAudioButtonControlBar(meeting: meeting)
        let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
              
        
        let endCallButton = DyteEndMeetingControlBarButton(meeting: meeting, alertViewController: presentingViewController) { buttons, alertButton in
            onLeaveMeetingCompletion?()
        }
        self.setButtons([micButton, videoButton, moreButton, endCallButton])

    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}
