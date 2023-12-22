//
//  DyteParticipantTileView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 06/01/23.
//

import UIKit
import DyteiOSCore


public class DyteParticipantTileView: DytePeerView {
     lazy var videoView: DyteVideoView = {
        if self.isDebugModeOn {
            print("Debug DyteUIKit | DyteParticipantTileView trying to create videoView through Lazy Property")
        }
       
    let view = DyteVideoView(participant: self.viewModel.participant, showSelfPreview: self.viewModel.showSelfPreviewVideo, showScreenShare: self.viewModel.showScreenShareVideoView)
        view.accessibilityIdentifier = "Dyte_Video_View"
        return view
    }()
    private let tokenColor = DesignLibrary.shared.color
    var nameTag: DyteMeetingNameTag!
    let spaceToken = DesignLibrary.shared.space
    public let viewModel: VideoPeerViewModel
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    private lazy var pinView : UIView = {
        let baseView = UIView()
        let imageView = UIUTility.createImageView(image: DyteImage(image:ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.fillSuperView(baseView, spaceToken.space1))
        return baseView
    }()
    
    private lazy var dyteAvatarView = {
        return DyteAvatarView(participant: self.viewModel.participant)
    }()
    
    public init(viewModel: VideoPeerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        initialiseView()
        updateView()
        registerUpdates()
    }
    
    convenience init(mobileClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant, isForLocalUser: Bool, showScreenShareVideoView: Bool = false) {
        self.init(viewModel: VideoPeerViewModel(mobileClient: mobileClient, participant: participant, showSelfPreviewVideo: isForLocalUser, showScreenShareVideoView: showScreenShareVideoView))
    }
    
    func pinView(show: Bool) {
        let heightWidth:CGFloat = 30
        if pinView.superview == nil {
            self.addSubview(pinView)
            pinView.backgroundColor = tokenColor.background.shade900
            pinView.set(.leading(self, tokenSpace.space3),
                        .top(self, tokenSpace.space3),
                        .height(heightWidth),
                        .width(heightWidth))
            pinView.layer.cornerRadius = tokenSpace.space1
        }
        pinView.isHidden = !show
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
private func initialiseView() {
    if self.isDebugModeOn {
        print("Debug DyteUIKit | New DyteParticipantTileView \(self) tile is created to load a video")
    }    
    self.addSubview(dyteAvatarView)
    dyteAvatarView.set(.centerView(self))
    
    self.addSubview(videoView)
    videoView.set(.fillSuperView(self))
    nameTag = DyteMeetingNameTag(meeting: self.viewModel.mobileClient, participant: self.viewModel.participant)
    self.addSubview(nameTag)
    nameTag.set(.leading(self, spaceToken.space3),
                .bottom(self, spaceToken.space3),
                .trailing(self, spaceToken.space3, .greaterThanOrEqual))
}
    
   private func updateView() {
       if self.isDebugModeOn {
           print("Debug DyteUIKit | DyteParticipantTileView refreshVideo() is called Internally through updateView()")
       }

        self.refreshVideo()
        self.pinView(show: self.viewModel.participant.isPinned)
    }
    
    public func refreshVideo() {
        if self.isDebugModeOn {
            print("Debug DyteUIKit | DyteParticipantTileView refreshVideo() is called, Video Enable \(self.viewModel.participant.videoEnabled) Update is Screen name \(self.viewModel.participant.name)")
        }
        self.videoView.refreshView()
    }
    
    private func registerUpdates() {
        viewModel.nameUpdate = { [weak self]  in
            guard let self = self else {return}
            self.nameTag.refresh()
        }
        viewModel.nameInitialsUpdate = { [weak self]  in
            guard let self = self else {return}
            self.dyteAvatarView.refresh()
        }
        viewModel.audioUpdate = { [weak self]  in
            guard let self = self else {return}
            self.nameTag.refresh()
        }
        viewModel.loadNewParticipant = { [weak self] participant  in
            guard let self = self else {return}
            self.nameTag.set(participant: participant)
            self.dyteAvatarView.set(participant: participant)
            self.videoView.set(participant: participant)
        }
    }
    
    public override func removeFromSuperview() {
        if self.isDebugModeOn {
            print("Debug DyteUIKit | DyteParticipantTileView \(self) removeFromSuperview() is called")
        }
        self.videoView.removeFromSuperview()
        super.removeFromSuperview()
    }
    
    deinit {
        self.videoView.clean()
        if self.isDebugModeOn {
            print("Debug DyteUIKit | DyteParticipantTileView \(self) deinit is calling")
        }
    }
    
}
