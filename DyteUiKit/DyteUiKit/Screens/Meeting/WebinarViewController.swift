//
//  WebinarViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 17/04/23.
//

import UIKit
import DyteiOSCore

enum WebinarStageStatus {
    case canJoinStage
    case joiningStage
    case alreadyOnStage
    case leavingFromStage
    case canRequestToJoinStage
    case requestingToJoinStage
    case inRequestedStateToJoinStage
    case viewOnly
}


public class WebinarViewController: MeetingViewController {
    private var waitingView : WaitingRoomView?
    
    func createWaitingView(message: String) -> WaitingRoomView {
        let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
        waitingView.backgroundColor = self.view.backgroundColor
        self.baseContentView.addSubview(waitingView)
        waitingView.set(.fillSuperView(self.baseContentView))
        waitingView.button.isHidden = true
        waitingView.show(message: message)
        return waitingView
    }
    
    public override func refreshMeetingGrid() {
        super.refreshMeetingGrid()
        self.waitingView?.removeFromSuperview()
        let mediaPermission = dyteMobileClient.localUser.permissions.media
        
        if (mediaPermission.audioPermission == DyteMediaPermission.allowed || mediaPermission.video.permission == DyteMediaPermission.allowed) && dyteMobileClient.participants.active.isEmpty && StageStatus.getStageStatus(mobileClient: dyteMobileClient) == .canJoinStage {
            self.waitingView = createWaitingView(message: "The stage is empty\nTo begin the webinar, please join the stage or accept a join stage request from the participants tab.")
        } else if dyteMobileClient.participants.active.isEmpty {
            self.waitingView = createWaitingView(message: "Webinar has not yet been started")
        }
    }
    
    
    override func createBottomBar() {
        
        let controlBar = DyteWebinarControlBar(meeting: self.dyteMobileClient, delegate: nil, presentingViewController: self, meetingViewModel: self.viewModel) { button in
            
        } settingViewControllerCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.dyteMobileClient.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        self.view.addSubview(controlBar)
        controlBar.set(.sameLeadingTrailing(self.view),
                       .bottom(self.view))
        
        self.bottomBar = controlBar
        
    }
        
    
}

