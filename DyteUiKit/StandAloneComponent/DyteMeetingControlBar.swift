//
//  DyteMeetingControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore


open class DyteMeetingControlBar: DyteControlBar {
   
    override init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), meetingViewModel: MeetingViewModel, settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, appearance: appearance, meetingViewModel: meetingViewModel, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        let micButton = DyteAudioButtonControlBar(meeting: meeting)
        let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
        self.setButtons([micButton, videoButton])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}

open class DyteWebinarControlBar: DyteControlBar {
  
    private let meeting: DyteMobileClient
    private let onRequestButtonClick: (DyteControlBarButton)->Void
    private let presentingViewController: UIViewController
    private let selfListner: DyteEventSelfListner
    
    init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), meetingViewModel: MeetingViewModel, onRequestButtonClick:@escaping(DyteControlBarButton)->Void, settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        self.presentingViewController = presentingViewController
        self.onRequestButtonClick = onRequestButtonClick
        self.selfListner = DyteEventSelfListner(mobileClient: meeting)
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, meetingViewModel: meetingViewModel,settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        self.refreshBar()
        self.selfListner.observeWebinarStageStatus { status in
            self.refreshBar()
        }
    }
    
    
    private func getStageStatus() -> WebinarStageStatus {
        let state = self.meeting.stage.stageStatus
        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = self.meeting.localUser.permissions.media.video
            let audioPermission = self.meeting.localUser.permissions.media.audioPermission
            if videoPermission == DyteMediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            }
            else if videoPermission == DyteMediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == DyteMediaPermission.notAllowed && audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
        case .rejectedToJoinStage:
            return .canRequestToJoinStage
        case .onStage:
            return .alreadyOnStage
        case .requestedToJoinStage:
            return .inRequestedStateToJoinStage
        default:
            print("Not Handle")
        }
        return .canRequestToJoinStage
    }

    func refreshBar() {
        self.refreshBar(stageStatus: self.getStageStatus())
    }
    
    private func refreshBar(stageStatus: WebinarStageStatus) {        
        var arrButtons = [DyteControlBarButton]()
        if stageStatus == .alreadyOnStage {
            let micButton = DyteAudioButtonControlBar(meeting: meeting)
            arrButtons.append(micButton)
            let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
            arrButtons.append(videoButton)
        }
        var stageButton: DyteStageActionButtonControlBar?
        if stageStatus != .viewOnly {
            let button = DyteStageActionButtonControlBar(mobileClient: meeting, buttonState: stageStatus, presentingViewController: self.presentingViewController)
            arrButtons.append(button)
            stageButton = button
        }
        self.setButtons(arrButtons)
            //This is done so that we will get the notification after releasing the old stageButton, Now we will receive one notion
        stageButton?.addObserver()
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}
