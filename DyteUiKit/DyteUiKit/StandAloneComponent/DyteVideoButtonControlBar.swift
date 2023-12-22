//
//  DyteVideoButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 10/04/23.
//

import DyteiOSCore
import UIKit

open class  DyteVideoButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    
    public init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_video_enabled")), title: "Video On")
        self.setSelected(image: DyteImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Video off")
        self.selectedStateTintColor = tokenColor.status.danger
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        self.isSelected = !mobileClient.localUser.videoEnabled
        self.dyteSelfListner.observeSelfVideo { [weak self] enabled in
            guard let self = self else {return}
            self.isSelected = !enabled
        }
       
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.accessibilityIdentifier = "Video_ControlBarButton_Selected"
            }else {
                self.accessibilityIdentifier = "Video_ControlBarButton_UnSelected"
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: DyteControlBarButton) {
        button.showActivityIndicator()
        dyteSelfListner.toggleLocalVideo(completion: { enableVideo in
            button.isSelected = !enableVideo
            button.hideActivityIndicator()
        })
    }
    deinit {
        self.dyteSelfListner.clean()
    }
}

