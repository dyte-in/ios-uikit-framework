//
//  DyteMeetingNameTag.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public class DyteMeetingNameTag: DyteNameTag {
    private let meeting: DyteMobileClient
    private var participant: DyteMeetingParticipant
    
    public init(meeting: DyteMobileClient, participant: DyteMeetingParticipant, appearance: DyteNameTagAppearance = AppTheme.shared.nameTagAppearance) {
        self.participant = participant
        self.meeting = meeting
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled")), appearance: appearance, title: "")
        refresh()
    }
    
    func set(participant: DyteMeetingParticipant) {
        self.participant = participant
        refresh()
    }
    
    func refresh() {
        let name = self.participant.name
        if self.meeting.localUser.userId == self.participant.userId {
            self.lblTitle.text = "\(name) (you)"
        }else {
            self.lblTitle.text = name
        }
        self.setAudio(isEnabled: self.participant.audioEnabled)
    }
    
    private func setAudio(isEnabled: Bool) {
         if isEnabled {
             self.imageView.image = ImageProvider.image(named: "icon_mic_enabled")?.withRenderingMode(.alwaysTemplate)
             self.imageView.tintColor = appearance.desingLibrary.color.textColor.onBackground.shade1000
         }else {
             self.imageView.image = ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate)
             self.imageView.tintColor = appearance.desingLibrary.color.status.danger
         }
     }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
