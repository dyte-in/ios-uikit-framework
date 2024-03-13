//
//  WebinarViewModel.swift
//  DyteUiKit
//
//  Created by Shaunak Jagtap on 07/03/24.
//

import Foundation
import DyteiOSCore


protocol DyteStageDelegate: AnyObject {
    func onPresentRequestAdded(participant: DyteJoinedMeetingParticipant)
    func onPresentRequestWithdrawn(participant: DyteJoinedMeetingParticipant)
}

class WebinarViewModel {
    var stageDelegate: DyteStageDelegate?
    private let dyteMobileClient: DyteMobileClient
    
    public init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        dyteMobileClient.addStageEventsListener(stageEventsListener: self)
    }
}

extension WebinarViewModel: DyteStageEventListener {
    func onPresentRequestWithdrawn(participant: DyteJoinedMeetingParticipant) {
        stageDelegate?.onPresentRequestWithdrawn(participant: participant)
    }
    
    func onRemovedFromStage() {
        
    }
    
    func onStageRequestsUpdated(accessRequests: [DyteJoinedMeetingParticipant]) {
        
    }
    
    func onStageStatusUpdated(stageStatus: StageStatus) {
        
    }
    
    func onAddedToStage() {
        
    }
    
    func onParticipantRemovedFromStage(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onParticipantStartedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onParticipantStoppedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onPresentRequestAccepted(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onPresentRequestAdded(participant: DyteJoinedMeetingParticipant) {
        stageDelegate?.onPresentRequestAdded(participant: participant)
    }
    
    func onPresentRequestClosed(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    
    public func onPresentRequestReceived() {
        
    }
    
    public func onPresentRequestRejected(participant: DyteJoinedMeetingParticipant) {
        
    }
}
