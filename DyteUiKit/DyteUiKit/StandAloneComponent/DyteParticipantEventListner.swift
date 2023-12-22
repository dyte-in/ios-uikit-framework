//
//  DyteParticipantEventListner.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/02/23.
//

import DyteiOSCore

class DyteParticipantUpdateEventListner  {
    private var participantAudioStateCompletion:((Bool)->Void)?
    private var participantVideoStateCompletion:((Bool)->Void)?
    private var participantObserveAudioStateCompletion:((Bool,DyteParticipantUpdateEventListner)->Void)?
    private var participantObserveVideoStateCompletion:((Bool,DyteParticipantUpdateEventListner)->Void)?
    private var participantPinStateCompletion:((Bool)->Void)?
    private var participantUnPinStateCompletion:((Bool)->Void)?
    private let isDebugModeOn = DyteUiKit.isDebugModeOn

    let participant: DyteJoinedMeetingParticipant
    
    init(participant: DyteJoinedMeetingParticipant) {
        self.participant = participant
        participant.addParticipantUpdateListener(participantUpdateListener: self)
    }
    
    public func observeAudioState(update:@escaping(_ isEnabled: Bool,_ observer: DyteParticipantUpdateEventListner)->Void) {
        participantObserveAudioStateCompletion = update
    }
    
    public func observeVideoState(update:@escaping(_ isEnabled: Bool,_ observer: DyteParticipantUpdateEventListner)->Void){
        participantObserveVideoStateCompletion = update
    }
    
    public func muteAudio(completion:@escaping(_ isEnabled: Bool)->Void) {
        self.participantAudioStateCompletion = completion
        try?self.participant.disableAudio()
    }
    
    public func muteVideo(completion:@escaping(_ isEnabled: Bool)->Void) {
        self.participantVideoStateCompletion = completion
        try?self.participant.disableVideo()
    }
    
    public func pin(completion:@escaping(Bool)->Void) {
        self.participantPinStateCompletion = completion
        try?self.participant.pin()
    }
    
    public func unPin(completion:@escaping(Bool)->Void) {
        self.participantUnPinStateCompletion = completion
        try?self.participant.unpin()
    }
    
    
    public func clean() {
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
    }
}

extension DyteParticipantUpdateEventListner: DyteParticipantUpdateListener {
    func onAudioUpdate(isEnabled: Bool) {
        self.participantObserveAudioStateCompletion?(isEnabled, self)
        self.participantAudioStateCompletion?(isEnabled)
        self.participantAudioStateCompletion = nil
    }
    
    func onPinned() {
        self.participantPinStateCompletion?(true)
        self.participantPinStateCompletion = nil
    }
    
    func onRemovedAsActiveSpeaker() {
        
    }
    
    func onScreenShareEnded() {
        
    }
    
    func onScreenShareStarted() {
        
    }
    
    func onSetAsActiveSpeaker() {
        
    }
    
    func onUnpinned() {
        self.participantUnPinStateCompletion?(true)
        self.participantUnPinStateCompletion = nil
    }
    
    func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    func onVideoUpdate(isEnabled: Bool) {
        self.participantObserveVideoStateCompletion?(isEnabled,self)
        self.participantVideoStateCompletion?(isEnabled)
        self.participantVideoStateCompletion = nil
    }
}


public class DyteWaitListParticipantUpdateEventListner  {
    
    var participantJoinedCompletion:((DyteMeetingParticipant)->Void)?
    var participantRemovedCompletion:((DyteMeetingParticipant)->Void)?
    var participantRequestAcceptedCompletion:((DyteMeetingParticipant)->Void)?
    var participantRequestRejectCompletion:((DyteMeetingParticipant)->Void)?
    
    let mobileClient: DyteMobileClient
    
    init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        self.mobileClient.addWaitlistEventsListener(waitlistEventsListener: self)
    }
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    public func clean() {
        removeRegisterListner()
    }
    public func acceptWaitingRequest(participant: DyteWaitlistedParticipant) {
        try?participant.acceptWaitListedRequest()
    }
    
    public func rejectWaitingRequest(participant: DyteWaitlistedParticipant) {
        try?participant.rejectWaitListedRequest()
    }
    
    private func removeRegisterListner() {
        self.mobileClient.removeWaitlistEventsListener(waitlistEventsListener: self)
    }
    
    deinit{
        print("DyteParticipantEventListner deallocing")
    }
}

extension DyteWaitListParticipantUpdateEventListner: DyteWaitlistEventsListener {
    public func onWaitListParticipantAccepted(participant: DyteWaitlistedParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onWaitListParticipantAccepted \(participant.name)")
        }
        DispatchQueue.main.async {
            self.participantRequestAcceptedCompletion?(participant)
        }
    }
    
    public func onWaitListParticipantRejected(participant: DyteWaitlistedParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onWaitListParticipantRejected \(participant.name) \(participant.id) self \(participant.id)")
        }
        self.participantRequestRejectCompletion?(participant)
    }
    
    
    public func onWaitListParticipantClosed(participant: DyteWaitlistedParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onWaitListParticipantClosed \(participant.name)")
        }
        self.participantRemovedCompletion?(participant)
    }

    public func onWaitListParticipantJoined(participant: DyteWaitlistedParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onWaitListParticipantJoined \(participant.name)")
        }
        self.participantJoinedCompletion?(participant)

    }
 
    
}
