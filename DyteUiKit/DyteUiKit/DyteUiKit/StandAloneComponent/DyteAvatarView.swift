//
//  DyteAvatarView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore


public class DyteAvatarView: UIView {
    private let profileImageView: BaseImageView = UIUTility.createImageView(image: nil)
    private let initialName: DyteText = UIUTility.createLabel(text: "")
    private var participant: DyteMeetingParticipant
    
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
        initialName.addSubview(profileImageView)
        profileImageView.set(.fillSuperView(initialName))
        
        let heightWidht = 100.0
        initialName.font = UIFont.boldSystemFont(ofSize: 30)
        initialName.backgroundColor = tokenColor.brand.shade500
        initialName.set(.centerView(self),
                        .width(heightWidht),
                        .height(heightWidht))
        initialName.layer.cornerRadius = heightWidht/2.0
        initialName.layer.masksToBounds = true
    }
    
    public func refresh() {
        if let path = participant.picture {
            self.showImage(path: path)
        }
        self.setInitials(name: participant.name)
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
