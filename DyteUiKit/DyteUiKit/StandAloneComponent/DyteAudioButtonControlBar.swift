//
//  DyteAudioButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 13/06/23.
//

import DyteiOSCore

open class  DyteAudioButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((DyteAudioButtonControlBar)->Void)?

    public init(meeting: DyteMobileClient, onClick:((DyteAudioButtonControlBar)->Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        self.mobileClient = meeting
        self.onClick = onClick
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled")), title: "Mic on", appearance: appearance)
        self.setSelected(image: DyteImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mic off")
        self.selectedStateTintColor = tokenColor.status.danger
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        self.isSelected = !mobileClient.localUser.audioEnabled

        self.dyteSelfListner.observeSelfAudio { [weak self] enabled in
            guard let self = self else {return}
            self.isSelected = !enabled
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.accessibilityIdentifier = "Mic_ControlBarButton_Selected"
            }else {
                self.accessibilityIdentifier = "Mic_ControlBarButton_UnSelected"
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func onClick(button: DyteAudioButtonControlBar) {
        button.showActivityIndicator()
        self.accessibilityIdentifier = "ControlBar_Audio_"
        self.dyteSelfListner.toggleLocalAudio(completion: { enableAudio in
            button.hideActivityIndicator()
            button.isSelected = !enableAudio
            self.onClick?(button)
        })
    }
    
    deinit {
        self.dyteSelfListner.clean()
    }
  
}
