//
//  ParticipantTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 13/02/23.
//

import UIKit
import DyteiOSCore


class ParticipantTableViewCell: BaseTableViewCell {
    let profileAvatarViewBaseView : BaseView = BaseView()
    
    var profileAvatarView: DyteAvatarView = {
        let view = DyteAvatarView()
        view.setInitialName(font: UIFont.boldSystemFont(ofSize: 12))
        return view
    }()
    let spaceToken = DesignLibrary.shared.space

    
    private lazy var pinView : UIView = {
        let baseView = UIView()
        let imageView = DyteUIUTility.createImageView(image: DyteImage(image:ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.leading(baseView, spaceToken.space1, .lessThanOrEqual),
                      .trailing(baseView, spaceToken.space0, .lessThanOrEqual),
                      .top(baseView, spaceToken.space0, .lessThanOrEqual),
                      .bottom(baseView, spaceToken.space1, .lessThanOrEqual),
                      .height(15),
                      .width(15))
        return baseView
    }()

    let profileImageWidth = dyteSharedTokenSpace.space9
        
    let nameLabel: DyteLabel = {
        let label = DyteUIUTility.createLabel(alignment: .left)
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = dyteSharedTokenColor.textColor.onBackground.shade900
        label.numberOfLines = 0
        return label
    }()
    
    let buttonStackView = {
        return DyteUIUTility.createStackView(axis: .horizontal, spacing: 8)
    }()
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Views
    func setupView() {
        let baseView = UIView()
        createSubView(on: baseView)
        contentView.addSubview(baseView)
        baseView.set(.below(self.cellSeparatorTop, dyteSharedTokenSpace.space3),
                     .above(cellSeparatorBottom, dyteSharedTokenSpace.space3),       .sameLeadingTrailing(cellSeparatorBottom))
    }
    

    func setPinView(isHidden: Bool) {
        self.pinView.isHidden  = isHidden
    }
    
    func createSubView(on baseView: UIView) {
        contentView.backgroundColor = dyteSharedTokenColor.background.shade1000
        baseView.addSubViews(profileAvatarViewBaseView, nameLabel, buttonStackView)
        profileAvatarViewBaseView.addSubview(profileAvatarView)
        profileAvatarView.set(.fillSuperView(profileAvatarViewBaseView))
        
        profileAvatarViewBaseView.set(.leading(baseView),
                             .top(baseView, 0.0 , .greaterThanOrEqual)
                             ,.centerY(baseView), .height(profileImageWidth), .width(profileImageWidth))
        profileAvatarViewBaseView.addSubViews(pinView)
        pinView.set(.trailing(profileAvatarViewBaseView),
                    .top(profileAvatarViewBaseView))
        
        nameLabel.set(.after(profileAvatarViewBaseView, dyteSharedTokenSpace.space3),
                      .centerY(profileAvatarViewBaseView),
                      .top(baseView, 0.0, .greaterThanOrEqual))
        buttonStackView.set(.after(nameLabel, dyteSharedTokenSpace.space2, .greaterThanOrEqual),
                            .centerY(profileAvatarViewBaseView),
                            .trailing(baseView, 10),
                            .top(baseView, 0.0, .greaterThanOrEqual)
        )
    }
}





