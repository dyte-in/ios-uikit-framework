//
//  DyteSwitchCameraButtonControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

open class  DyteSwitchCameraButtonControlBar: DyteControlBarButton {
    private let meeting: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    
    public init(meeting: DyteMobileClient) {
        self.meeting = meeting
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: meeting)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_flipcamera_topbar")))
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        if meeting.localUser.permissions.media.canPublishVideo {
            self.isHidden = !meeting.localUser.videoEnabled
            self.dyteSelfListner.observeSelfVideo { enabled in
                self.isHidden = !enabled
            }
        }
        else {
            self.isHidden = false
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: DyteControlBarButton) {
        dyteSelfListner.toggleCamera()
    }
    
    deinit {
        self.dyteSelfListner.clean()
    }
}

