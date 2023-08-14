//
//  File.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/02/23.
//

import DyteiOSCore


class DyteMeetingEventListner  {
    
    private var selfAudioStateCompletion:((Bool)->Void)?
    private var recordMeetingStartCompletion:((Bool)->Void)?
    private var recordMeetingStopCompletion:((Bool)->Void)?
    private var selfJoinedStateCompletion:((Bool)->Void)?
    private var selfLeaveStateCompletion:((Bool)->Void)?
    private var participantLeaveStateCompletion:((DyteMeetingParticipant)->Void)?
    private var participantJoinStateCompletion:((DyteMeetingParticipant)->Void)?
    
    var dyteMobileClient: DyteMobileClient
    
    init(mobileClient: DyteMobileClient) {
        self.dyteMobileClient = mobileClient
        self.dyteMobileClient.addRecordingEventsListener(recordingEventsListener: self)
        self.dyteMobileClient.addParticipantEventsListener(participantEventsListener: self)
    }
    
    func clean() {
        self.dyteMobileClient.removeParticipantEventsListener(participantEventsListener: self)
        self.dyteMobileClient.removeRecordingEventsListener(recordingEventsListener: self)
    }
    
    private let isDebugModeOn = DyteUiKit.isDebugModeOn

    public func startRecordMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.recordMeetingStartCompletion = completion
        self.dyteMobileClient.recording.start()
    }
    
    public func stopRecordMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.recordMeetingStopCompletion = completion
        self.dyteMobileClient.recording.stop()
    }
    

    public func joinMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.selfJoinedStateCompletion = completion
        self.dyteMobileClient.joinRoom() 
    }
    
    public func leaveMeeting(completion:@escaping(_ success: Bool)->Void) {
        self.selfLeaveStateCompletion = completion
        self.dyteMobileClient.leaveRoom() 
    }
    
    public func observeParticipantJoin(update:@escaping(_ participant: DyteMeetingParticipant)->Void) {
        participantJoinStateCompletion = update
    }
    
    public func observeParticipantLeave(update:@escaping(_ participant: DyteMeetingParticipant)->Void) {
        participantLeaveStateCompletion = update
    }
    
    deinit{
        print("DyteMeetingEventListner deallocing")
    }
}

extension DyteMeetingEventListner: DyteRecordingEventsListener {
    
    func onMeetingRecordingEnded() {
        self.recordMeetingStopCompletion?(true)
        self.recordMeetingStopCompletion = nil
    }

    func onMeetingRecordingStarted() {
        self.recordMeetingStartCompletion?(true)
        self.recordMeetingStartCompletion = nil
    }

    func onMeetingRecordingStateUpdated(state: DyteRecordingState) {
        
    }

    func onMeetingRecordingStopError(e: KotlinException) {
        
    }
}

extension DyteMeetingEventListner: DyteParticipantEventsListener {
    func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onScreenShareEnded(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    func onScreenShareStarted(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        
    }
    
    func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
    func onNoActiveSpeaker() {
        
    }
    

    func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onParticipantJoin \(participant.audioEnabled) \(participant.name) totalCount \(self.dyteMobileClient.participants.joined) participants")
        }
        self.participantJoinStateCompletion?(participant)
    }
    
    func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onParticipantLeave \(self.dyteMobileClient.participants.active.count)")
        }
        self.participantLeaveStateCompletion?(participant)
    }
    
    func onScreenSharesUpdated() {
        
    }
    
    func onUpdate(participants: DyteRoomParticipants) {
        
    }
    
    func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
   
}

