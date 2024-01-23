//
//  ParticipantTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 13/02/23.
//

import UIKit

class ParticipantTableViewCell: BaseTableViewCell {

    let profileImageView: BaseImageView = {
        let imageView = DyteUIUTility.createImageView(image: nil)
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white
        return imageView
    }()
    
    let profileImageWidth = dyteSharedTokenSpace.space8
    
    var widthConstraint: NSLayoutConstraint! = nil
    let nameLabel: DyteText = {
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
    
    func createSubView(on baseView: UIView) {
        contentView.backgroundColor = dyteSharedTokenColor.background.shade1000
        baseView.addSubViews(profileImageView, nameLabel, buttonStackView)
        profileImageView.set(.leading(baseView),
                             .top(baseView, 0.0 , .greaterThanOrEqual)
                             ,.centerY(baseView), .height(profileImageWidth), .width(profileImageWidth))
        widthConstraint = profileImageView.get(.width)
        profileImageView.layer.cornerRadius = widthConstraint.constant/2.0
        nameLabel.set(.after(profileImageView, dyteSharedTokenSpace.space3),
                      .centerY(profileImageView),
                      .top(baseView, 0.0, .greaterThanOrEqual))
        buttonStackView.set(.after(nameLabel, dyteSharedTokenSpace.space2, .greaterThanOrEqual),
                            .centerY(profileImageView),
                            .trailing(baseView, 10),
                            .top(baseView, 0.0, .greaterThanOrEqual)
        )
                    
    }
}





