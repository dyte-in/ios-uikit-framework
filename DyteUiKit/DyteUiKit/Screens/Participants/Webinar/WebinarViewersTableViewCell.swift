//
//  ParticipantInCallTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class WebinarViewersTableViewCell: ParticipantTableViewCell {
   
    let moreButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_more_tabbar"))), dyteButtonState: .active)
        return button
    }()
    private var viewModel: WebinarViewersTableViewCellModel?
    var buttonMoreClick:((DyteButton) -> Void)?

    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = UIUTility.createStackView(axis: .horizontal, spacing: 0)
        self.buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        self.moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }
    
   @objc func moreButtonClick(button: DyteButton) {
       self.buttonMoreClick?(button)
    }
}

extension WebinarViewersTableViewCell: ConfigureView {
    var model: WebinarViewersTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: WebinarViewersTableViewCellModel) {
        viewModel = model
        widthConstraint.constant = 0.0
        self.profileImageView.setImage(image: model.image) {[unowned self] _ in
            self.widthConstraint.constant = profileImageWidth
        }
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
        self.moreButton.isHidden = !model.showMoreButton
       
    }
    
}
