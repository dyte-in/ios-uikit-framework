//
//  DyteMoreMenuBottomSheet.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public class DyteMoreMenuBottomSheet {
    private let presentingViewController: UIViewController
    private let settingViewControllerCompletion:(()->Void)?
    private let meeting: DyteMobileClient

   init(menus: [MenuType], meeting: DyteMobileClient, presentingViewController: UIViewController, settingViewControllerCompletion:(()->Void)? = nil) {
       self.settingViewControllerCompletion = settingViewControllerCompletion
       self.presentingViewController = presentingViewController
       self.meeting = meeting
      
       create(menus: menus)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var moreMenu: DyteMoreMenu!
    
    func create(menus: [MenuType]) {
         moreMenu = DyteMoreMenu(features: menus, onSelect: { [weak self] menuType in
            guard let self = self else {return}
            switch menuType {
            case.muteAllAudio:
                self.muteAllAudio()
            case.muteAllVideo:
                self.muteAllVideo()
            case.shareMeetingUrl:
                self.shareMeetingUrl()
            case .chat:
                self.onChatTapped()
            case .poll:
                self.launchPollsScreen()
            case .recordingStart:
                self.meeting.recording.start()
            case .recordingStop:
                self.meeting.recording.stop()
            case .settings:
                self.launchSettingScreen()
            case .plugins:
                self.onPluginTapped()
            case .particpants:
                self.launchParticipantScreen()
            default:
                print("Not Supported for now")
            }
        })
         moreMenu.accessibilityIdentifier = "MoreMenu_BottomSheet"
    }
    
    func reload(title:String? = nil, features: [MenuType]) {
        moreMenu.reload(title:title, features: features)
    }
    
    func show() {
        moreMenu.show(on: self.presentingViewController.view)
    }

    func hide() {
        moreMenu.hideSheet()
    }
}

private extension DyteMoreMenuBottomSheet {
    private func launchPollsScreen() {
        let controller = ShowPollsViewController(dyteMobileClient: self.meeting)
        self.presentingViewController.present(controller, animated: true)
        Shared.data.setPollViewCount(totalPolls: self.meeting.polls.polls.count)
    }
    
    private func launchSettingScreen() {
        let controller = SettingViewController(nameTag: self.meeting.localUser.name, dyteMobileClient: self.meeting, completion: self.settingViewControllerCompletion)
        controller.view.backgroundColor = self.presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(controller, animated: true)
    }
    
    private func shareMeetingUrl() {
        if let name = URL(string: "https://demo.dyte.io/v2/meeting?id=\(self.meeting.meta.roomName)"), !name.absoluteString.isEmpty {
          let objectsToShare = [name]
          let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.presentingViewController.present(activityVC, animated: true, completion: nil)
        } else {
          // show alert for not available
        }
    }
    
    private func muteAllAudio() {
        meeting.participants.disableAllAudio()
    }
    
    private func muteAllVideo() {
        try?meeting.participants.disableAllVideo()
    }
    
    private func launchParticipantScreen() {
        var controller: UIViewController  = ParticipantViewController(viewModel: ParticipantViewControllerModel(mobileClient: self.meeting))
        if self.meeting.meta.meetingType == DyteMeetingType.webinar {
            controller = WebinarParticipantViewController(viewModel: WebinarParticipantViewControllerModel(mobileClient: self.meeting))
        }
        controller.view.backgroundColor = self.presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(controller, animated: true)
    }
    
    private func onChatTapped() {
        let controller = ChatViewController(dyteMobileClient: self.meeting)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(navigationController, animated: true, completion: nil)
        Shared.data.setChatReadCount(totalMessage: self.meeting.chat.messages.count)
    }
   
    private func onPluginTapped() {
        let controller = PluginViewController(polls: meeting.plugins.all)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        presentingViewController.present(navigationController, animated: false, completion: nil)
    }
}
