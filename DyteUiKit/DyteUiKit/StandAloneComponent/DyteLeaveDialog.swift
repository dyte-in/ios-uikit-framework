//
//  DyteLeaveDialog.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore




public class DyteLeaveDialog {
    static let onEndMeetingForAllButtonPress: Notification.Name = Notification.Name("onEndMeetingForAllButtonPress")
    

    public  enum DyteLeaveDialogAlertButtonType {
        case willLeaveMeeting
        case didLeaveMeeting
        
        case willEndMeetingForAll
        case didEndMeetingForAll

        case cancel
        case nothing
    }
    private let meeting: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((DyteLeaveDialogAlertButtonType)->Void)?

    init(meeting: DyteMobileClient, onClick:((DyteLeaveDialogAlertButtonType)->Void)? = nil) {
        self.meeting = meeting
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: meeting)
        self.onClick = onClick
    }
    
    deinit {
        self.dyteSelfListner.clean()
    }
    
    public func show(on viewController: UIViewController) {
        self.showEndCallAlert(title: "Leave call?", message: "Do you really want to leave this call?", presentingController: viewController)
    }
    
    private func showEndCallAlert(title: String, message: String, presentingController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .default, handler: { action in
            self.onClick?(.willLeaveMeeting)
            self.dyteSelfListner.leaveMeeting(kickAll: false, completion: { success in
                // We have not used weak self, Because we want Delayed deallocation of UIAlertController in memory
                self.onClick?(.didLeaveMeeting)
            })
        }))
        
        if self.meeting.localUser.permissions.host.canKickParticipant {
            alert.addAction(UIAlertAction(title: "End Meeting for all", style: .default, handler: { action in
                self.onClick?(.willEndMeetingForAll)
                NotificationCenter.default.post(name: Self.onEndMeetingForAllButtonPress, object: nil)
                self.dyteSelfListner.leaveMeeting(kickAll: true, completion: { success in
                    self.onClick?(.didEndMeetingForAll)
                })
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.onClick?(.cancel)
        }))
        alert.view.accessibilityIdentifier = "Leave_Meeting_Alert"
        presentingController.present(alert, animated: true, completion: nil)
    }

}
