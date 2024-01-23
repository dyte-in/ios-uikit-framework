//
//  WebinarAlert.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 17/04/23.
//

import UIKit
import DyteiOSCore


public class WebinarAlertView: UIView, ConfigureWebinerAlertView {
    let baseView = UIView()
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    private lazy var dyteSelfListner: DyteEventSelfListner = {
        return DyteEventSelfListner(mobileClient: self.meeting)
    }()
    
    let lblTop: DyteText = {
        let lbl = DyteUIUTility.createLabel(text: "Joining webinar stage" , alignment: .left)
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        return lbl
     }()
    
    let selfPeerView: DyteParticipantTileView
    var meeting: DyteMobileClient
    
    public init(meetingClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        self.meeting = meetingClient
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: meeting, participant: participant, showSelfPreviewVideo: true))
        super.init(frame: .zero)
        setupSubview()
    }
    
    func setupSubview() {
        createSubview()
        btnMic.isSelected = !self.meeting.localUser.audioEnabled
        btnVideo.isSelected = !self.meeting.localUser.videoEnabled
        btnMic.addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        btnVideo.addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let btnVideo: DyteButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_video_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
    
    let btnMic: DyteButton = {
        let button =  DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
   
    let lblBottom: DyteText = {
        let lbl = DyteUIUTility.createLabel(text: "Upon joining the stage, your video & audio as shown above will be visible to all participants.", alignment: .left)
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.numberOfLines = 0
        return lbl
    }()

    public let confirmAndJoinButton: DyteButton = {
        let button = DyteUIUTility.createButton(text: "Confirm & join stage")
        return button
    }()
    
    public let cancelButton: DyteButton = {
        let button = DyteUIUTility.createButton(text: "Cancel")
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
    
    private func createSubView(baseView: UIView) {
        let btnStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: dyteSharedTokenSpace.space6)
        btnStackView.addArrangedSubviews(btnMic, btnVideo)
        baseView.addSubViews(lblTop, selfPeerView, btnStackView, lblBottom, confirmAndJoinButton, cancelButton)
        lblTop.set(.sameLeadingTrailing(baseView),
                   .top(baseView))
        selfPeerView.clipsToBounds = true
        
        selfPeerView.set(UIDevice.current.userInterfaceIdiom == .pad ? .aspectRatio(0.45) : .aspectRatio(0.85),
                         .height(500,.lessThanOrEqual),
                         .below(lblTop, dyteSharedTokenSpace.space6),
                      .sameLeadingTrailing(baseView, dyteSharedTokenSpace.space6))
        
        btnStackView.set(.below(selfPeerView, dyteSharedTokenSpace.space4),
                         .centerX(baseView))
        
        lblBottom.set(.sameLeadingTrailing(baseView),
                      .below(btnStackView, dyteSharedTokenSpace.space6))
        confirmAndJoinButton.set(.below(lblBottom, dyteSharedTokenSpace.space6),
                       .sameLeadingTrailing(baseView))
        cancelButton.set(.below(confirmAndJoinButton, dyteSharedTokenSpace.space4),
                       .sameLeadingTrailing(baseView),
                       .bottom(baseView))
     }

    private func createSubview() {
        baseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .two, radius: borderRadiusType)
        baseView.layer.masksToBounds = true
        
        self.addSubview(baseView)
        let alertContentBaseView = UIView()
        baseView.addSubview(alertContentBaseView)
        self.createSubView(baseView: alertContentBaseView)
        baseView.backgroundColor = dyteSharedTokenColor.background.shade900
        self.backgroundColor = dyteSharedTokenColor.background.shade1000.withAlphaComponent(0.9)
        baseView.set(.sameLeadingTrailing(self, dyteSharedTokenSpace.space7),
                     .centerY(self),.top(self, dyteSharedTokenSpace.space8, .greaterThanOrEqual))
        alertContentBaseView.set(.fillSuperView(baseView, dyteSharedTokenSpace.space4))
    }
    
        @objc func clickMic(button: DyteButton) {
            button.showActivityIndicator()
            dyteSelfListner.toggleLocalAudio(completion: { [weak self] isEnabled in
                guard let self = self else {return}
                button.hideActivityIndicator()
                self.selfPeerView.nameTag.refresh()
                button.isSelected = !isEnabled
            })
    
        }
        
        @objc func clickVideo(button: DyteButton) {
            button.showActivityIndicator()
            dyteSelfListner.toggleLocalVideo(completion: { [weak self] isEnabled  in
                guard let self = self else {return}
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                self.loadSelfVideoView()
            })
        }
    
    public func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
}
