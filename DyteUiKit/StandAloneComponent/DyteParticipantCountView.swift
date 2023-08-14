//
//  DyteParticipantCountView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public class DyteParticipantCountView: DyteText {
    private let meeting: DyteMobileClient
    
    init(meeting: DyteMobileClient, appearance: DyteTextAppearance = AppTheme.shared.participantCountAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.text = self.meeting.meta.meetingTitle
        self.meeting.addParticipantEventsListener(participantEventsListener: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        self.meeting.removeParticipantEventsListener(participantEventsListener: self)
    }
    
    func update() {
        if self.meeting.participants.joined.count <= 1 {
            self.text = "Only you"
        } else {
            self.text = "\(self.meeting.participants.joined.count) participants"
        }
    }
    
}

extension DyteParticipantCountView: DyteParticipantEventsListener {
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        
    }
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
    public func onNoActiveSpeaker() {
        
    }
    
    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        self.update()
    }
    
    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        self.update()
    }
    
    public func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onScreenShareEnded(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onScreenShareStarted(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onScreenSharesUpdated() {
        
    }
    
    public func onUpdate(participants: DyteRoomParticipants) {
        
    }
    
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
  
}
