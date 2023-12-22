//
//  DyteVideoPeerViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 06/01/23.
//

import DyteiOSCore

public class VideoPeerViewModel {
    
    public  var audioUpdate: (()->Void)?
    public  var videoUpdate: (()->Void)?
    public  var loadNewParticipant: ((DyteJoinedMeetingParticipant)->Void)?

    public  var nameInitialsUpdate: (()->Void)?
    public var nameUpdate: (()->Void)?
    public var profileImagePathUpdate: (()->Void)?
    let showSelfPreviewVideo: Bool
    var participant: DyteJoinedMeetingParticipant!
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    let mobileClient: DyteMobileClient
    let showScreenShareVideoView: Bool

    public init(mobileClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant, showSelfPreviewVideo: Bool, showScreenShareVideoView: Bool = false) {
        self.showSelfPreviewVideo = showSelfPreviewVideo
        self.showScreenShareVideoView = showScreenShareVideoView
        self.mobileClient = mobileClient
        self.participant = participant
        update()
    }
    
    func set(participant: DyteJoinedMeetingParticipant) {
        self.participant = participant
        self.loadNewParticipant?(participant)
        update()
    }
    
    func update() {
        self.refreshNameTag()
        self.refreshInitialName()
        participantUpdateListner = DyteParticipantUpdateEventListner(participant: participant)
        addUpdatesListner()
    }
    
    
    public func refreshInitialName() {
       
        nameInitialsUpdate?()
    }
    
    public func refreshNameTag() {
       
        nameUpdate?()
    }
    
    var participantUpdateListner: DyteParticipantUpdateEventListner?
    
    public func addUpdatesListner() {
        participantUpdateListner?.observeAudioState(update: { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.audioUpdate?()
        })
        participantUpdateListner?.observeVideoState(update: { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.videoUpdate?()
        })
    
    }
}




