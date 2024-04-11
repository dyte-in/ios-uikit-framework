//
//  DyteParticipantCountView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public class DyteParticipantCountView: DyteLabel {
    private let meeting: DyteMobileClient
    
    public init(meeting: DyteMobileClient, appearance: DyteTextAppearance = AppTheme.shared.participantCountAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.text = ""
        self.meeting.addParticipantEventsListener(participantEventsListener: self)
        self.meeting.addMeetingRoomEventsListener(meetingRoomEventsListener: self)
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.meeting.removeParticipantEventsListener(participantEventsListener: self)
    }
    
    private func update() {
        if self.meeting.participants.joined.count <= 1 {
            self.text = "Only you"
        } else {
            self.text = "\(self.meeting.participants.joined.count) participants"
        }
    }
    
}

extension DyteParticipantCountView: DyteMeetingRoomEventsListener {
    
    public func onActiveTabUpdate(id: String, tabType: ActiveTabType) {
        
    }
    
    public func onMeetingInitCompleted() {
        
    }
    
    public func onMeetingInitFailed(exception: KotlinException) {
        
    }
    
    public func onMeetingInitStarted() {
        
    }
    
    public func onMeetingRoomJoinCompleted() {
        
    }
    
    public func onMeetingRoomJoinFailed(exception: KotlinException) {
        
    }
    
    public func onMeetingRoomJoinStarted() {
        
    }
    
    public func onMeetingRoomLeaveCompleted() {
        
    }
    
    public func onMeetingRoomLeaveStarted() {
        
    }
    
    public func onConnectedToMeetingRoom() {
        
    }
    
    public func onConnectingToMeetingRoom() {
        
    }
    
    public func onDisconnectedFromMeetingRoom() {
        
    }
    
    public func onMeetingRoomConnectionFailed() {
        
    }
    
    public func onMeetingRoomDisconnected() {
        
    }
    
    public func onMeetingRoomReconnectionFailed() {
        
    }
    
    public func onReconnectedToMeetingRoom() {
        update()
    }
    
    public func onReconnectingToMeetingRoom() {
        
    }
    
    
}

extension DyteParticipantCountView: DyteParticipantEventsListener {
    public func onAllParticipantsUpdated(allParticipants: [DyteParticipant]) {}
    
    public func onUpdate(participants: DyteRoomParticipants) {}
    
    public func onScreenShareEnded(participant_ participant: DyteScreenShareMeetingParticipant) {}
    
    public func onScreenShareStarted(participant_ participant: DyteScreenShareMeetingParticipant) {}
    
    public func onScreenShareEnded(participant: DyteJoinedMeetingParticipant) {}
    
    public func onScreenShareStarted(participant: DyteJoinedMeetingParticipant) {}
    
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {}
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {}
    
    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {}
    
    public func onNoActiveSpeaker() {}
    
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
    
    public func onScreenSharesUpdated() {
        
    }
    
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
  
}
