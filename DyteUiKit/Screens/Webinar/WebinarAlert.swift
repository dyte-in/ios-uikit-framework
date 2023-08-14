//
//  WebinarAlert.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 17/04/23.
//

import UIKit
import DyteiOSCore


public class WebinarAlertView: UIView {
    
    let baseView = UIView()
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    private lazy var dyteSelfListner: DyteEventSelfListner = {
        return DyteEventSelfListner(mobileClient: self.meeting)
    }()
    
    let lblTop: DyteText = {
        let lbl = UIUTility.createLabel(text: "Joining webinar stage" , alignment: .left)
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        return lbl
     }()
    
    let selfPeerView: DyteParticipantTileView
    var meeting: DyteMobileClient
    
    public init(meetingClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        self.meeting = meetingClient
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: meeting, showScreenShareVideo: false, participant: participant, showSelfPreviewVideo: true))
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
        button.backgroundColor = tokenColor.background.shade800
        return button
    }()
    
    let btnMic: DyteButton = {
        let button =  DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.backgroundColor = tokenColor.background.shade800
        return button
    }()
   
    let lblBottom: DyteText = {
        let lbl = UIUTility.createLabel(text: "Upon joining the stage, your video & audio as shown above will be visible to all participants.", alignment: .left)
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.numberOfLines = 0
        return lbl
    }()

    let btnBottom1: DyteButton = {
        let button = UIUTility.createButton(text: "Confirm & join stage")
        return button
    }()
    
    let btnBottom2: DyteButton = {
        let button = UIUTility.createButton(text: "Cancel")
        button.backgroundColor = tokenColor.background.shade800
        return button
    }()
    
    private func createSubView(baseView: UIView) {
        let btnStackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space6)
        btnStackView.addArrangedSubviews(btnMic, btnVideo)
        baseView.addSubViews(lblTop, selfPeerView, btnStackView, lblBottom, btnBottom1, btnBottom2)
        lblTop.set(.sameLeadingTrailing(baseView),
                   .top(baseView))
        selfPeerView.clipsToBounds = true
        
        selfPeerView.set(.aspectRatio(0.85),
                         .below(lblTop, tokenSpace.space6),
                      .sameLeadingTrailing(baseView, tokenSpace.space6))
        
        btnStackView.set(.below(selfPeerView, tokenSpace.space4),
                         .centerX(baseView))
        
        lblBottom.set(.sameLeadingTrailing(baseView),
                      .below(btnStackView, tokenSpace.space6))
        btnBottom1.set(.below(lblBottom, tokenSpace.space6),
                       .sameLeadingTrailing(baseView))
        btnBottom2.set(.below(btnBottom1, tokenSpace.space4),
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
        baseView.backgroundColor = tokenColor.background.shade900
        self.backgroundColor = tokenColor.background.shade1000.withAlphaComponent(0.9)
        baseView.set(.sameLeadingTrailing(self, tokenSpace.space7),
                     .centerY(self),.top(self, tokenSpace.space8, .greaterThanOrEqual))
        alertContentBaseView.set(.fillSuperView(baseView, tokenSpace.space4))
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
