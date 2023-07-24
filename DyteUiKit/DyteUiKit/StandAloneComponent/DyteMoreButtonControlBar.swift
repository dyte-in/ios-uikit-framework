//
//  DyteMoreButtonControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

open class  DyteMoreButtonControlBar: DyteControlBarButton {
    private let meeting: DyteMobileClient
    private let presentingViewController: UIViewController
    private let viewModel: MeetingViewModel
    private let settingViewControllerCompletion:(()->Void)?
    private var bottomSheet: DyteMoreMenuBottomSheet!
    public init(mobileClient: DyteMobileClient, presentingViewController: UIViewController, meetingViewModel: MeetingViewModel, settingViewControllerCompletion:(()->Void)? = nil) {
        self.meeting = mobileClient
        self.settingViewControllerCompletion = settingViewControllerCompletion
        self.viewModel = meetingViewModel
        self.presentingViewController = presentingViewController
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_more_tabbar")), title: "More")
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: DyteControlBarButton) {
        button.notificationBadge.isHidden = true
        createMoreMenu(shown: self.presentingViewController.view)
    }
    
    
    private func createMoreMenu(shown onView: UIView) {
        var menus = [MenuType]()
//        menus.append(.shareMeetingUrl)
        let recordingState = self.meeting.recording.recordingState
        let permissions = self.meeting.localUser.permissions
        
        let hostPermission = permissions.host
        if hostPermission.canTriggerRecording {
             if recordingState == .recording || recordingState == .starting {
                 menus.append(.recordingStop)
              } else {
                  menus.append(.recordingStart)
             }
         }
        let pluginPermission = permissions.plugins
       
        if pluginPermission.canLaunch {
            menus.append(.plugins)
        }
        
        let pollPermission = permissions.polls
        if pollPermission.canCreate || pollPermission.canView || pollPermission.canVote {
            let count = self.meeting.polls.polls.count
            menus.append(.poll(notificationMessage: count > 0 ? "\(count)" : ""))
        }
        var message = ""
        let pending = self.meeting.getPendingParticipantCount()
       
        if pending > 0 {
            message = "\(pending)"
        }
        
        
        let chatCount = self.meeting.chat.messages.count
        menus.append(contentsOf: [.chat(notificationMessage: chatCount > 0 ? "\(chatCount)" : ""), .settings, .particpants(notificationMessage: message), .cancel])
        
        self.bottomSheet = DyteMoreMenuBottomSheet(menus: menus, meeting: self.meeting, presentingViewController: self.presentingViewController, meetingViewModel: self.viewModel)
        
        self.bottomSheet.show()
    }
}
