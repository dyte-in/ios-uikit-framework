//
//  DyteUiKitEngine.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/01/23.
//

import Foundation
import DyteiOSCore
import UIKit

public class DyteNotificationConfig {
    public class DyteNotification {
        public var playSound = true
        public var showToast = true
        
        init(playSound: Bool = true, showToast: Bool = true) {
            self.playSound = playSound
            self.showToast = showToast
        }
    }
    public var participantJoined = DyteNotification()
    public var participantLeft = DyteNotification()
    public var newChatArrived = DyteNotification()
    public var newPollArrived = DyteNotification()
    
}


public protocol DyteUiKitLifeCycle {
    func webinarJoinStagePopupDidShow()
    func webinarJoinStagePopupDidHide(click buttonType: DyteUiKit.WebinarAlertButtonType)
    func meetingScreenDidShow()
    func meetingScreenWillShow()

}


public protocol DyteUIKitFlowCoordinatorDelegate {
    func showSetUpScreen(completion:()->Void) -> SetupViewControllerDataSource?
    func showGroupCallMeetingScreen(meeting: DyteMobileClient, completion: @escaping()->Void) -> UIViewController?
    func showWebinarMeetingScreen(meeting: DyteMobileClient, completion: @escaping()->Void) -> UIViewController?
}

public class DyteUiKit {
    
    public enum WebinarAlertButtonType {
        case confirmAndJoin
        case cancel
    }
    
    private  let configurationV2: DyteMeetingInfoV2?
    private  let configuration: DyteMeetingInfo?
    public let mobileClient: DyteMobileClient
    public let appTheme: AppTheme
    public let designLibrary: DesignLibrary
    public let notification = DyteNotificationConfig()
    public let flowDelegate: DyteUIKitFlowCoordinatorDelegate?
    var completion: (()->Void)!

#if DEBUG
   static let isDebugModeOn = false
#else
   static let isDebugModeOn = false
#endif
    
    public  var delegate: DyteUiKitLifeCycle? {
        didSet {
            Shared.data.delegate = delegate
        }
    }
    
    public  init(meetingInfo: DyteMeetingInfo, flowDelegate: DyteUIKitFlowCoordinatorDelegate? = nil) {
        mobileClient = DyteiOSClientBuilder().build()
        self.flowDelegate = flowDelegate
        designLibrary = DesignLibrary.shared
        appTheme = AppTheme(designTokens: designLibrary)
        configuration = meetingInfo
        configurationV2 = nil
    }
    
    public init(meetingInfoV2: DyteMeetingInfoV2, flowDelegate: DyteUIKitFlowCoordinatorDelegate? = nil) {
        self.flowDelegate = flowDelegate
        mobileClient = DyteiOSClientBuilder().build()
        designLibrary = DesignLibrary.shared
        appTheme = AppTheme(designTokens: designLibrary)
        configurationV2 = meetingInfoV2
        configuration = nil
    }
    
    public func startMeeting(completion:@escaping()->Void) -> UIViewController {
        Shared.data.initialise()
        Shared.data.notification = notification
        self.completion = completion
        if let viewController = self.flowDelegate?.showSetUpScreen(completion: completion) {
            viewController.delegate = self
            return viewController
        } else {
           return getSetUpViewController(configuration: self.configuration, configurationV2: self.configurationV2, completion: completion)
        }
    }
}

extension DyteMobileClient {
    
    func getWaitlistCount() -> Int {
        return self.participants.waitlisted.count
    }
    
    func getWebinarCount() -> Int {
        return self.stage.accessRequests.count
    }
    
    func getPendingParticipantCount() -> Int {
        return getWebinarCount() + getWaitlistCount()
    }
}

extension DyteUiKit {
    
    private func getSetUpViewController(configuration: DyteMeetingInfo?,configurationV2: DyteMeetingInfoV2?, completion:@escaping()->Void) -> SetupViewController {
        if let config = configuration {
            let controller =  SetupViewController(meetingInfo: config, mobileClient: self.mobileClient, completion: completion)
            controller.delegate = self
            return controller
        } else {
            let controller =  SetupViewController(meetingInfo:configurationV2!, mobileClient: self.mobileClient, completion: completion)
            controller.delegate = self
            return controller
        }
    }
    
    private func launchMeetingScreen(on viewController: UIViewController, completion:@escaping()->Void) {
        Shared.data.delegate?.meetingScreenWillShow()
        let meetingViewController = getMeetingScreen(meetingType: self.mobileClient.meta.meetingType, completion: completion)
        meetingViewController.modalPresentationStyle = .fullScreen
        viewController.present(meetingViewController, animated: true) {
            Shared.data.delegate?.meetingScreenDidShow()
        }
        notificationDelegate?.didReceiveNotification(type: .Joined)
    }
    
    private func getMeetingScreen(meetingType: DyteMeetingType,  completion:@escaping()->Void) -> UIViewController {
        if mobileClient.meta.meetingType == DyteMeetingType.groupCall {
            if let viewController = self.flowDelegate?.showGroupCallMeetingScreen(meeting: self.mobileClient, completion: completion) {
                return viewController
            }
            return MeetingViewController(meeting: mobileClient, completion: completion)
        }
        else if mobileClient.meta.meetingType == DyteMeetingType.livestream {
            return LivestreamViewController(dyteMobileClient: mobileClient, completion: completion)
        }
        
        else if mobileClient.meta.meetingType == DyteMeetingType.webinar {
            if let viewController = self.flowDelegate?.showWebinarMeetingScreen(meeting: self.mobileClient, completion: completion) {
                return viewController
            }
            return WebinarViewController(meeting: mobileClient, completion: completion)
        }
        fatalError("Unknown Meeting type not supported")
    }
}

extension DyteUiKit : SetupViewControllerDelegate {
    
    public func userJoinedMeetingSuccessfully(sender: UIViewController) {
        launchMeetingScreen(on: sender, completion: self.completion)
    }
}
