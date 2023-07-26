//
//  DyteSwitchCameraButtonControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

open class  DyteSwitchCameraButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    
    public init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_flipcamera_topbar")))
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        
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

