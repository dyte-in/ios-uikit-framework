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
    private let viewModel: MeetingViewModel
    private let settingViewControllerCompletion:(()->Void)?
    private let meeting: DyteMobileClient

   init(menus: [MenuType], meeting: DyteMobileClient, presentingViewController: UIViewController, meetingViewModel: MeetingViewModel, settingViewControllerCompletion:(()->Void)? = nil) {
       self.settingViewControllerCompletion = settingViewControllerCompletion
       self.viewModel = meetingViewModel
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
    }
    
    func show() {
        moreMenu.show(on: self.presentingViewController.view)

    }
    
    private func launchPollsScreen() {
        let controller = ShowPollsViewController(dyteMobileClient: self.meeting)
        self.presentingViewController.present(controller, animated: true)
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
        let controller = ChatViewController(dyteMobileClient: self.meeting, meetingViewModel: self.viewModel)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(navigationController, animated: true, completion: nil)
    }
   
    private func onPluginTapped() {
        let controller = PluginViewController(polls: meeting.plugins.all)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        presentingViewController.present(navigationController, animated: false, completion: nil)
    }
}
