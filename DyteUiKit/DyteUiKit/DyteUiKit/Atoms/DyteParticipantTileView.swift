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
    public var nameTag: DyteMeetingNameTag!
    let spaceToken = DesignLibrary.shared.space
    public let viewModel: VideoPeerViewModel
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    private lazy var pinView : UIView = {
        let baseView = UIView()
        let imageView = DyteUIUTility.createImageView(image: DyteImage(image:ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.leading(baseView, spaceToken.space1),
                      .trailing(baseView, spaceToken.space1),
                      .top(baseView, spaceToken.space1),
                      .bottom(baseView, spaceToken.space1))
        imageView.get(.leading)?.priority = .defaultHigh
        imageView.get(.trailing)?.priority = .defaultHigh
        imageView.get(.top)?.priority = .defaultHigh
        imageView.get(.bottom)?.priority = .defaultHigh
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
        nameTag.backgroundColor = nameTag.backgroundColor?.withAlphaComponent(0.6)
    }
    
    public convenience init(mobileClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant, isForLocalUser: Bool, showScreenShareVideoView: Bool = false) {
        self.init(viewModel: VideoPeerViewModel(mobileClient: mobileClient, participant: participant, showSelfPreviewVideo: isForLocalUser, showScreenShareVideoView: showScreenShareVideoView))
    }
    
    public func pinView(show: Bool) {
       

        if pinView.superview == nil {
            self.addSubview(pinView)
            pinView.backgroundColor = tokenColor.background.shade900.withAlphaComponent(0.6)
            pinView.set(.leading(self, dyteSharedTokenSpace.space3, .lessThanOrEqual),
                        .top(self, dyteSharedTokenSpace.space3, .lessThanOrEqual),
                        .height(0),
                        .width(0))
            pinView.layer.cornerRadius = dyteSharedTokenSpace.space1
            
        }
        pinView.isHidden = !show
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updatePinViewHeightConstraint()
        self.updateAvatorViewHeightConstraint()
        self.updateNameTagViewHeightConstraint()
    }
   
    private func updateAvatorViewHeightConstraint() {
        var width = bounds.height * 0.4
        if bounds.height > bounds.width {
            width = bounds.width * 0.4
        }
        
        let maxHeightWidth:CGFloat = 100
        let minHeightWidth:CGFloat = 40
  
        if width > maxHeightWidth ||  width < minHeightWidth {
            if width > maxHeightWidth {
                dyteAvatarView.get(.width)?.constant = maxHeightWidth
                dyteAvatarView.get(.height)?.constant = maxHeightWidth
            }
            if width < minHeightWidth {
                dyteAvatarView.get(.width)?.constant = minHeightWidth
                dyteAvatarView.get(.height)?.constant = minHeightWidth
            }
        }else {
            dyteAvatarView.get(.width)?.constant = width
            dyteAvatarView.get(.height)?.constant = width
        }
    }
    
    private func updatePinViewHeightConstraint() {
        let width = bounds.width * 0.2
        let maxHeightWidth:CGFloat = 30
        let minHeightWidth:CGFloat = 15
  
        if width > maxHeightWidth ||  width < minHeightWidth {
            if width > maxHeightWidth {
                pinView.get(.width)?.constant = maxHeightWidth
                pinView.get(.height)?.constant = maxHeightWidth
            }
            if width < minHeightWidth {
                pinView.get(.width)?.constant = minHeightWidth
                pinView.get(.height)?.constant = minHeightWidth
            }
        }else {
            pinView.get(.width)?.constant = width
            pinView.get(.height)?.constant = width
        }
    }
    private func updateNameTagViewHeightConstraint() {
        var height = bounds.height * 0.12
        let maxHeightWidth:CGFloat = 36
        let minHeightWidth:CGFloat = 18
        let maxFontSize = 16.0
        let minFontSize = 9.0
        let factorWidth = maxHeightWidth - minHeightWidth
        let fontFactor = maxFontSize - minFontSize
        let maxLeadingBottom = spaceToken.space3
        let minLeadingBottom = spaceToken.space1
        let leadingBottomFactor = maxLeadingBottom - minLeadingBottom

        if height > maxHeightWidth ||  height < minHeightWidth {
            if height > maxHeightWidth {
                height = maxHeightWidth
            }
            if height < minHeightWidth {
                height = minHeightWidth
            }
        }
        if nameTag.get(.height) == nil {
            nameTag.set(.height(height))
        }
        nameTag.get(.height)?.constant = height
       

        let newWidth = height - minHeightWidth
        let fontSize = newWidth*(fontFactor/factorWidth) + minFontSize
        let leadingBottomSpace = newWidth*(leadingBottomFactor/factorWidth) + minLeadingBottom
        nameTag.lblTitle.font = UIFont.systemFont(ofSize: fontSize)
        nameTag.get(.leading)?.constant = leadingBottomSpace
        nameTag.get(.bottom)?.constant = -leadingBottomSpace
        pinView.get(.leading)?.constant = leadingBottomSpace
        pinView.get(.top)?.constant = leadingBottomSpace
    }

   
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

  private func initialiseView() {
    if self.isDebugModeOn {
        print("Debug DyteUIKit | New DyteParticipantTileView \(self) tile is created to load a video")
    }    
    self.addSubview(dyteAvatarView)
    dyteAvatarView.set(.centerView(self),
                       .height(0),
                       .width(0))
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

public class DyteParticipantTileContainerView : UIView {
    public var tileView: DyteParticipantTileView!
    
    public func prepareForReuse() {
        tileView?.removeFromSuperview()
        tileView = nil
    }
    
    public func setParticipant(meeting: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        prepareForReuse()
        let tile = DyteParticipantTileView(mobileClient: meeting, participant: participant, isForLocalUser: false, showScreenShareVideoView: false)
        self.tileView = tile
        self.addSubview(tile)
        tile.set(.fillSuperView(self))
    }
}
