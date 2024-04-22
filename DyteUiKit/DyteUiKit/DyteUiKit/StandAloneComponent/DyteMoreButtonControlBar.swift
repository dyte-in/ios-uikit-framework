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
    private unowned let presentingViewController: UIViewController
    private let settingViewControllerCompletion:(()->Void)?
    private var bottomSheet: DyteMoreMenuBottomSheet!
    
    public init(meeting: DyteMobileClient, presentingViewController: UIViewController, settingViewControllerCompletion:(()->Void)? = nil) {
        self.meeting = meeting
        self.settingViewControllerCompletion = settingViewControllerCompletion
        self.presentingViewController = presentingViewController
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_more_tabbar")), title: "More")
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        self.accessibilityIdentifier = "TabBar_More_Button"
        NotificationCenter.default.addObserver(self, selector: #selector(newChatArrived(notification:)), name: Notification.Name("Notify_NewChatArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newPollArrived(notification:)), name: Notification.Name("Notify_NewPollArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(participantUpdate(notification:)), name: Notification.Name("Notify_ParticipantListUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recordingUpdate(notification:)), name: Notification.Name("Notify_RecordingUpdate"), object: nil)

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: DyteControlBarButton) {
        button.notificationBadge.isHidden = true
        createMoreMenu(shown: self.presentingViewController.view)
    }
    
    
    private func createMoreMenu(shown onView: UIView) {
                     
        self.bottomSheet = DyteMoreMenuBottomSheet(menus: getMenu(), meeting: self.meeting, presentingViewController: self.presentingViewController)
        self.bottomSheet.show()
    }
    
    private func getMenu() -> [MenuType] {
        var menus = [MenuType]()
        
        if meeting.localUser.permissions.host.canMuteAudio {
            menus.append(.muteAllAudio)
        }
        
        if meeting.localUser.permissions.host.canMuteVideo {
            menus.append(.muteAllVideo)
        }
        
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
            let count = Shared.data.getUnviewPollCount(totalPolls:self.meeting.polls.polls.count)
            menus.append(.poll(notificationMessage: count > 0 ? "\(count)" : ""))
        }
       
        menus.append(.settings)
        
        let chatCount = Shared.data.getUnreadChatCount(totalMessage: self.meeting.chat.messages.count)
        menus.append(.chat(notificationMessage: chatCount > 0 ? "\(chatCount)" : ""))
        
        var message = ""
        let pending = self.meeting.getPendingParticipantCount()
       
        if pending > 0 {
            message = "\(pending)"
        }
        menus.append(contentsOf: [.particpants(notificationMessage: message), .cancel])
        return menus
    }
    
    @objc
    func newChatArrived(notification: NSNotification) {
        self.bottomSheet?.reload(features: getMenu())
    }
    
    @objc
    func newPollArrived(notification: NSNotification) {
        self.bottomSheet?.reload(features: getMenu())
    }
    
    @objc
    func recordingUpdate(notification: NSNotification) {
        self.bottomSheet?.reload(features: getMenu())
    }
    
    @objc
    func participantUpdate(notification: NSNotification) {
        self.bottomSheet?.reload(features: getMenu())
    }
    
    public func hideBottomSheet() {
        self.bottomSheet?.hide()
    }
}
