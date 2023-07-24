//
//  DyteEndMeetingButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/06/23.
//
import UIKit
import DyteiOSCore

open class DyteEndMeetingControlBarButton: DyteControlBarButton {
    private let meeting: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((DyteEndMeetingControlBarButton,DyteLeaveDialog.DyteLeaveDialogAlertButtonType)->Void)?
    public var shouldShowAlertOnClick = true
    private let alertPresentingController: UIViewController
   
    public init(meeting: DyteMobileClient, alertViewController: UIViewController , onClick:((DyteEndMeetingControlBarButton, DyteLeaveDialog.DyteLeaveDialogAlertButtonType)->Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        self.meeting = meeting
        self.alertPresentingController = alertViewController
        self.onClick = onClick
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: meeting)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_end_meeting_tabbar")), title: "", appearance: appearance)
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        DispatchQueue.main.async() {
            self.backgroundColor = appearance.desingLibrary.color.status.danger
            self.set(.width(48),
                     .height(48))
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
     @objc open func onClick(button: DyteEndMeetingControlBarButton) {
        if shouldShowAlertOnClick {
            let dialog = DyteLeaveDialog(meeting: self.meeting) { alertAction in
                if alertAction == .willLeaveMeeting || alertAction == .willEndMeetingForAll {
                    self.showActivityIndicator()
                }else if alertAction == .didLeaveMeeting || alertAction == .didEndMeetingForAll {
                    self.hideActivityIndicator()
                    if alertAction == .didLeaveMeeting {
                        self.onClick?(self , .didLeaveMeeting)
                    }else if alertAction == .didEndMeetingForAll {
                        self.onClick?(self, .didEndMeetingForAll)
                    }
                }
            }
            dialog.show(on: self.alertPresentingController)
        }else {
            //When we are not showing alert then on clicking we can directly end call
            self.showActivityIndicator()
            self.dyteSelfListner.leaveMeeting(kickAll: false, completion: { [weak self] success in
                guard let self = self else {return}
                self.hideActivityIndicator()
                self.onClick?(button,.nothing)
            })
        }
    }
    
    deinit {
        self.dyteSelfListner.clean()
    }
}

