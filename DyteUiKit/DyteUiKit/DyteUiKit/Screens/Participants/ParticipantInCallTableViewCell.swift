//
//  ParticipantInCallTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class ParticipantInCallTableViewCell: ParticipantTableViewCell {
    let videoButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_video_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()
    
    let audioButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()
    var notificationBadge: DyteNotificationBadgeView?
    var moreButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_more_tabbar"))), dyteButtonState: .active)
        return button
    }()
    private var viewModel: ParticipantInCallTableViewCellModel?
    var buttonMoreClick:((DyteButton) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        profileAvatarView.backgroundColor = dyteSharedTokenColor.brand.shade500
        profileAvatarView.profileImageView.image = nil
        profileAvatarView.initialName.text = nil
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        notificationBadge?.isHidden = true
    }
    
    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: 0)
        videoButtonStackView.addArrangedSubviews(videoButton, audioButton)
        self.buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        self.moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }
    
   @objc func moreButtonClick(button: DyteButton) {
       self.buttonMoreClick?(button)
    }
}

extension ParticipantInCallTableViewCell: ConfigureView {
    var model: ParticipantInCallTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: ParticipantInCallTableViewCellModel) {
        viewModel = model
        self.profileAvatarView.set(participant: model.participantUpdateEventListner.participant)
        self.audioButton.isSelected = !model.participantUpdateEventListner.participant.audioEnabled
        self.videoButton.isSelected = !model.participantUpdateEventListner.participant.videoEnabled
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
        self.moreButton.isHidden = !model.showMoreButton
        model.participantUpdateEventListner.observeAudioState { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.audioButton.isSelected = !isEnabled
        }
        let participant = model.participantUpdateEventListner.participant.userId
        model.participantUpdateEventListner.observePinState { [weak self] isPinned, observer in
            guard let self = self else {return}
            self.setPinView(isHidden: !isPinned)
        }
        model.participantUpdateEventListner.observeVideoState { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.videoButton.isSelected = !isEnabled
        }
    }
    
}
