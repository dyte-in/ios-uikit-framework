//
//  ParticipantWaitingTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class BaseParticipantWaitingTableViewCell: ParticipantTableViewCell {
    let crossButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_cross"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.status.danger
        button.isSelected = false
        return button
    }()
    
    let tickButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_tick"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.status.success
        button.isSelected = false
        return button
    }()
    
    var buttonCrossClick:((DyteButton) -> Void)?
    var buttonTickClick:((DyteButton) -> Void)?
    
    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        self.buttonStackView.addArrangedSubviews(crossButton, tickButton)
        self.tickButton.addTarget(self, action: #selector(tickButtonClick(button:)), for: .touchUpInside)
        self.crossButton.addTarget(self, action: #selector(crossButtonClick(button:)), for: .touchUpInside)
    }
    
    @objc func tickButtonClick(button: DyteButton) {
         buttonTickClick?(button)
    }
    
    @objc func crossButtonClick(button: DyteButton) {
         buttonCrossClick?(button)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        crossButton.prepareForReuse()
        tickButton.prepareForReuse()
    }
}

class ParticipantWaitingTableViewCell: BaseParticipantWaitingTableViewCell {
    private var viewModel: ParticipantWaitingTableViewCellModel?
}

class OnStageWaitingRequestTableViewCell: BaseParticipantWaitingTableViewCell {
    private var viewModel: OnStageParticipantWaitingRequestTableViewCellModel?
}


extension OnStageWaitingRequestTableViewCell: ConfigureView {
    var model: OnStageParticipantWaitingRequestTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: OnStageParticipantWaitingRequestTableViewCellModel) {
        viewModel = model
        widthConstraint.constant = 0.0
        self.profileImageView.setImage(image: model.image) {[unowned self] _ in
            self.widthConstraint.constant = profileImageWidth
        }
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
    }
}
extension ParticipantWaitingTableViewCell: ConfigureView {
    var model: ParticipantWaitingTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: ParticipantWaitingTableViewCellModel) {
        viewModel = model
        widthConstraint.constant = 0.0
        self.profileImageView.setImage(image: model.image) {[unowned self] _ in
            self.widthConstraint.constant = profileImageWidth
        }
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
    }
}

