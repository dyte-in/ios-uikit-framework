//
//  DyteAvatarView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore


public class DyteAvatarView: UIView {
    private let profileImageView: BaseImageView = {
        let imageView = DyteUIUTility.createImageView(image: nil)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private let initialName: DyteText = DyteUIUTility.createLabel(text: "")
    private var participant: DyteMeetingParticipant?
    
    public init() {
        super.init(frame: .zero)
        self.createSubView()
        refresh()
    }
    
    public init(participant: DyteMeetingParticipant) {
        self.participant = participant
        super.init(frame: .zero)
        self.createSubView()
        refresh()
    }
    
    func set(participant: DyteMeetingParticipant) {
        self.participant = participant
        refresh()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubView() {
        self.addSubview(initialName)
        self.backgroundColor = dyteSharedTokenColor.brand.shade500
        self.addSubview(profileImageView)
        profileImageView.set(.fillSuperView(self))
        initialName.adjustsFontSizeToFitWidth = true
        initialName.font = UIFont.boldSystemFont(ofSize: 30)
        initialName.set(.leading(self, dyteSharedTokenSpace.space1),
                        .trailing(self, dyteSharedTokenSpace.space1),
                        .centerY(self),
                        .height(0))
        initialName.get(.leading)?.priority = .defaultHigh
        initialName.get(.trailing)?.priority = .defaultHigh
        self.layer.masksToBounds = true
    }
    
    
    private func updateInitialNameConstraints() {
        let multiplier: CGFloat = 0.4
        let height = bounds.height * multiplier
        let minheight: CGFloat = 20
        let maxheight: CGFloat = 40
        if height < minheight ||  height > maxheight  {
            if height < minheight {
                initialName.get(.height)?.constant = minheight
            }
            if height > maxheight {
                initialName.get(.height)?.constant = maxheight
            }
        }else {
            initialName.get(.height)?.constant = height
        }
        self.layer.cornerRadius = bounds.width/2.0
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateInitialNameConstraints()
    }
    
    public func refresh() {
        if let participant = self.participant {
            if let path = participant.picture {
                self.showImage(path: path)
            }
            self.setInitials(name: participant.name)
        }
    }
    
    func setInitialName(font: UIFont) {
        self.initialName.font = font
    }
    
    private func showImage(path: String) {
        if let url = URL(string: path) {
            self.profileImageView.isHidden = false
            self.profileImageView.setImage(image: DyteImage(url: url))
        }
    }
    
    private func setInitials(name: String) {
        self.initialName.text = self.getNameInitials(name: name.isEmpty ? "P" : name)
    }
    
    private func getNameInitials(name: String) -> String {
        var nameInitials = ""
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            formatter.style = .abbreviated
            nameInitials = formatter.string(from: components)
        }else {
            if let first = name.first {
                nameInitials = "\(first)"
            }else {
                nameInitials = ""
            }
        }
        return nameInitials
    }
}
