//
//  DyteWebinarControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 15/01/24.
//

import UIKit
import DyteiOSCore


public protocol DyteWebinarControlBarDataSource {
    func getMicControlBarButton(for stageStatus: WebinarStageStatus) ->  DyteControlBarButton?
    func getVideoControlBarButton(for stageStatus: WebinarStageStatus) ->  DyteControlBarButton?
    func getStageActionControlBarButton(for stageStatus: WebinarStageStatus) ->  DyteStageActionButtonControlBar?
}

open class DyteWebinarControlBar: DyteControlBar {
    private let meeting: DyteMobileClient
    private let onRequestButtonClick: (DyteControlBarButton)->Void
    private let presentingViewController: UIViewController
    private let selfListner: DyteEventSelfListner
    private var stageActionControlButton: DyteStageActionButtonControlBar?
    private let dataSource: DyteWebinarControlBarDataSource?
   
    init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, dataSource: DyteWebinarControlBarDataSource?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), onRequestButtonClick:@escaping(DyteControlBarButton)->Void, settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        self.dataSource = dataSource
        self.presentingViewController = presentingViewController
        self.onRequestButtonClick = onRequestButtonClick
        self.selfListner = DyteEventSelfListner(mobileClient: meeting, identifier: "Webinar Control Bar")
    
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        self.refreshBar()
        self.selfListner.observeWebinarStageStatus { status in
            self.refreshBar()
            self.stageActionControlButton?.updateButton(stageStatus: status)
        }
        self.selfListner.observeRequestToJoinStage { [weak self] in
            guard let self = self else {return}
            self.stageActionControlButton?.handleRequestToJoinStage()
        }
    }
    
    override func onRotationChange() {
        super.onRotationChange()
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
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

    deinit {
        self.selfListner.clean()
    }
    
    private func refreshBar() {
        self.refreshBar(stageStatus: self.getStageStatus())
        if UIScreen.isLandscape() {
            self.moreButton.superview?.isHidden = true
        }
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }
    
    private func refreshBar(stageStatus: WebinarStageStatus) {
        
        var arrButtons = [DyteControlBarButton]()
        
        if stageStatus == .alreadyOnStage {
            let micButton = self.dataSource?.getMicControlBarButton(for: stageStatus) ?? DyteAudioButtonControlBar(meeting: meeting)
            arrButtons.append(micButton)
            let videoButton = self.dataSource?.getVideoControlBarButton(for: stageStatus) ?? DyteVideoButtonControlBar(mobileClient: meeting)
            arrButtons.append(videoButton)
        }
        
        var stageButton: DyteStageActionButtonControlBar?
        if stageStatus != .viewOnly {
            let button = self.dataSource?.getStageActionControlBarButton(for: stageStatus) ?? DyteStageActionButtonControlBar(mobileClient: meeting, buttonState: stageStatus, presentingViewController: self.presentingViewController)
            arrButtons.append(button)
            stageButton = button
        }
        self.setButtons(arrButtons)
            //This is done so that we will get the notification after releasing the old stageButton, Now we will receive one notification
        stageButton?.addObserver()
        self.stageActionControlButton = stageButton
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}
