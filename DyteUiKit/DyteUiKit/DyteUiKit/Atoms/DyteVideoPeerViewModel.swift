//
//  DyteVideoPeerViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 06/01/23.
//

import DyteiOSCore

public class VideoPeerViewModel {
    
    public var audioUpdate: (()->Void)?
    public var videoUpdate: (()->Void)?
    public var loadNewParticipant: ((DyteJoinedMeetingParticipant)->Void)?

    public var nameInitialsUpdate: (()->Void)?
    public var nameUpdate: (()->Void)?
    
    let showSelfPreviewVideo: Bool
    var participant: DyteJoinedMeetingParticipant!
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    let mobileClient: DyteMobileClient
    let showScreenShareVideoView: Bool
    private var participantUpdateListner: DyteParticipantUpdateEventListner?

    public init(meeting: DyteMobileClient, participant: DyteJoinedMeetingParticipant, showSelfPreviewVideo: Bool, showScreenShareVideoView: Bool = false) {
        self.showSelfPreviewVideo = showSelfPreviewVideo
        self.showScreenShareVideoView = showScreenShareVideoView
        self.mobileClient = meeting
        self.participant = participant
        update()
    }
    
    public func set(participant: DyteJoinedMeetingParticipant) {
        self.participant = participant
        self.loadNewParticipant?(participant)
        update()
    }
    
    public func refreshInitialName() {
        nameInitialsUpdate?()
    }
    
    public func refreshNameTag() {
        nameUpdate?()
    }
    
    
    private func addUpdatesListner() {
        participantUpdateListner?.observeAudioState(update: { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.audioUpdate?()
        })
        participantUpdateListner?.observeVideoState(update: { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.videoUpdate?()
        })
    }
    
    private func update() {
        self.refreshNameTag()
        self.refreshInitialName()
        participantUpdateListner?.clean()
        participantUpdateListner = DyteParticipantUpdateEventListner(participant: participant)
        addUpdatesListner()
    }
}




