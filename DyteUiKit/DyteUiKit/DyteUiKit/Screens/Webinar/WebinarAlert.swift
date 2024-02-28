//
//  WebinarAlert.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 17/04/23.
//

import UIKit
import DyteiOSCore


public class WebinarAlertView: UIView, ConfigureWebinerAlertView, AdaptableUI {
    public var portraitConstraints = [NSLayoutConstraint]()
    
    public var landscapeConstraints = [NSLayoutConstraint]()
    
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
    private var previousOrientationIsLandscape = UIScreen.isLandscape()

    public init(meetingClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        self.meeting = meetingClient
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: meeting, participant: participant, showSelfPreviewVideo: true))
        super.init(frame: .zero)
        setupSubview()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func onOrientationChange() {
        let currentOrientationIsLandscape = UIScreen.isLandscape()
        if previousOrientationIsLandscape != currentOrientationIsLandscape {
            previousOrientationIsLandscape = currentOrientationIsLandscape
            onRotationChange()
        }
    }
    
    
    private func onRotationChange() {
        setUpConstraintAsPerOrientation()
    }
    
    private func setUpConstraintAsPerOrientation() {
        self.applyConstraintAsPerOrientation()
    }
    
    func setupSubview() {
        createSubview()
        setUpConstraintAsPerOrientation()
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
        lbl.textAlignment = .center
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
    
       
    private func createSubview() {
        baseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .two, radius: borderRadiusType)
        baseView.layer.masksToBounds = true
        
        self.addSubview(baseView)
        let alertContentBaseView = UIView()
        baseView.addSubview(alertContentBaseView)
        self.createSubView(baseView: alertContentBaseView)
        baseView.backgroundColor = dyteSharedTokenColor.background.shade900
        self.backgroundColor = dyteSharedTokenColor.background.shade1000.withAlphaComponent(0.9)
        baseView.set(.centerX(self),
                     .centerY(self))
        let portraitPeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: baseView)
        portraitConstraints.append(portraitPeerViewWidth)
        
        let landscapePeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: baseView)
        landscapeConstraints.append(landscapePeerViewWidth)
        alertContentBaseView.set(.fillSuperView(baseView, dyteSharedTokenSpace.space4))
    }
    
    private func createSubView(baseView: UIView) {
        
        let topView = UIView()
        let bottomView = UIView()
        baseView.addSubViews(topView,bottomView)
        
        func addTopViewPortraitConstraint() {
            topView.set(.top(baseView),.sameLeadingTrailing(baseView))
            
            portraitConstraints.append(contentsOf: [topView.get(.top)!,
                                                    topView.get(.leading)!,
                                                    topView.get(.trailing)!])
        }
        
        func addTopViewLandscapeConstraint() {
            topView.set(.top(baseView, dyteSharedTokenSpace.space6),.leading(baseView),
                        .bottom(baseView, dyteSharedTokenSpace.space6))
            landscapeConstraints.append(contentsOf: [topView.get(.top)!,
                                                     topView.get(.leading)!,
                                                     topView.get(.bottom)!])
        }
        
        addTopViewPortraitConstraint()
        addTopViewLandscapeConstraint()
        
        
        
        func addBottomViewPortraitConstraint() {
            bottomView.set(.below(topView),
                           .sameLeadingTrailing(baseView),
                           .bottom(baseView))
            portraitConstraints.append(contentsOf: [bottomView.get(.top)!,
                                                    bottomView.get(.leading)!,
                                                    bottomView.get(.trailing)!,
                                                    bottomView.get(.bottom)!])
            
        }
        
        func addBottomViewLandscapeConstraint() {
            bottomView.set(.top(baseView),
                           .trailing(baseView),
                           .after(topView),
                           .bottom(baseView))
            landscapeConstraints.append(contentsOf: [bottomView.get(.top)!,
                                                     bottomView.get(.leading)!,
                                                     bottomView.get(.trailing)!,
                                                     bottomView.get(.bottom)!])
        }
        addBottomViewPortraitConstraint()
        addBottomViewLandscapeConstraint()
        
        self.createTopView(topView: topView)
        self.createSubViewForAlertContent(baseView: bottomView)
    }
    
    private func createTopView(topView: UIView) {
        let peerContentView = UIView()
        topView.addSubViews(lblTop, peerContentView)
        peerContentView.addSubview(selfPeerView)
       
        lblTop.set(.sameLeadingTrailing(topView),
                   .top(topView))
        
        selfPeerView.clipsToBounds = true
        peerContentView.set(.below(lblTop, dyteSharedTokenSpace.space6),
                            .bottom(topView),
                            .sameLeadingTrailing(topView))
        
        selfPeerView.set(.top(peerContentView,0,.greaterThanOrEqual),
                         .centerY(peerContentView),
                         .centerX(peerContentView),
                         .leading(peerContentView,dyteSharedTokenSpace.space4,.greaterThanOrEqual))
        
        let portraitPeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewWidth)
        let portraitPeerViewHeight =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.95).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewHeight)

        let landscapePeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        landscapeConstraints.append(landscapePeerViewWidth)
        
        let landscapePeerViewHeight =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.75).getConstraint(for: selfPeerView)
        landscapeConstraints.append(landscapePeerViewHeight)

    }
    
    private func createSubViewForAlertContent(baseView: UIView) {
        let btnStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: dyteSharedTokenSpace.space6)
        btnStackView.addArrangedSubviews(btnMic, btnVideo)
        let bottomBtnStackView = DyteUIUTility.createStackView(axis: .vertical, spacing: dyteSharedTokenSpace.space4)
        bottomBtnStackView.addArrangedSubviews(confirmAndJoinButton, cancelButton)
        baseView.addSubViews(btnStackView, lblBottom, bottomBtnStackView)
        
        btnStackView.set(.top(baseView, dyteSharedTokenSpace.space4),
                         .centerX(baseView))
        
        lblBottom.set(.sameLeadingTrailing(baseView),
                      .below(btnStackView, dyteSharedTokenSpace.space6))
        bottomBtnStackView.set(.below(lblBottom, dyteSharedTokenSpace.space6),
                               .centerX(baseView),
                               .leading(baseView,dyteSharedTokenSpace.space4, .greaterThanOrEqual),
                               .bottom(baseView))
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
