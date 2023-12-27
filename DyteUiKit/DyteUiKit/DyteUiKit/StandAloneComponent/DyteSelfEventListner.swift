//
//  DyteSelfEventListner.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/02/23.
//

import DyteiOSCore

class DyteEventSelfListner  {
    private static var currentInstance = 0
    enum Reconnection {
        case start
        case success
        case failed
    }
    private var selfAudioStateCompletion:((Bool)->Void)?
    private var selfVideoStateCompletion:((Bool)->Void)?
    private var selfObserveVideoStateCompletion:((Bool)->Void)?
    private var selfObserveAudioStateCompletion:((Bool)->Void)?
    
    private var selfObserveWebinarStageStatus:((StageStatus)->Void)?
    private var selfObserveRequestToJoinStage:(()->Void)?

    private var selfWebinarJoinedStateCompletion:((Bool)->Void)?
    private var selfWebinarLeaveStateCompletion:((Bool)->Void)?
    private var selfRequestToGetPermissionJoinedStateCompletion:((Bool)->Void)?
    private var selfCancelRequestToGetPermissionToJoinStageCompletion:((Bool)->Void)?
    private var selfMeetingInitStateCompletion:((Bool)->Void)?
    private var selfLeaveStateCompletion:((Bool)->Void)?
    private var selfRemovedStateCompletion:((Bool)->Void)?
    private var selfTabBarSyncStateCompletion:((String)->Void)?
    private var selfObserveReconnectionStateCompletion:((Reconnection)->Void)?

    var waitListStatusUpdate:((WaitListStatus)->Void)?
    
    var dyteMobileClient: DyteMobileClient
    let identifier: String
    init(mobileClient: DyteMobileClient, identifier: String = "Default") {
        self.identifier = identifier
        self.dyteMobileClient = mobileClient
        mobileClient.addMeetingRoomEventsListener(meetingRoomEventsListener: self)
        mobileClient.addSelfEventsListener(selfEventsListener: self)
        mobileClient.addStageEventsListener(stageEventsListener: self)
        Self.currentInstance += 1
    }
    
    func clean() {
        dyteMobileClient.removeMeetingRoomEventsListener(meetingRoomEventsListener: self)
        dyteMobileClient.removeSelfEventsListener(selfEventsListener: self)
        dyteMobileClient.removeStageEventsListener(stageEventsListener: self)

    }
    
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    func toggleLocalAudio(completion: @escaping(_ isEnabled: Bool)->Void) {
        self.selfAudioStateCompletion = completion
        if self.dyteMobileClient.localUser.audioEnabled == true {
            try?self.dyteMobileClient.localUser.disableAudio()
        } else {
            self.dyteMobileClient.localUser.enableAudio()
        }
    }
   
    public func observeSelfVideo(update:@escaping(_ enabled: Bool)->Void) {
        selfObserveVideoStateCompletion = update
    }
    
    public func observeSelfAudio(update:@escaping(_ enabled: Bool)->Void) {
        selfObserveAudioStateCompletion = update
    }
    
    public func observeSelfRemoved(update:((_ success: Bool)->Void)?) {
        self.selfRemovedStateCompletion = update
    }
    
    public func observePluginScreenShareTabSync(update:((_ id: String)->Void)?) {
        self.selfTabBarSyncStateCompletion = update
    }
    
    public func observeMeetingReconnectionState(update: @escaping(_ state: Reconnection)-> Void) {
        self.selfObserveReconnectionStateCompletion = update
    }
    
    func toggleLocalVideo(completion: @escaping(_ isEnabled: Bool)->Void) {
        self.selfVideoStateCompletion = completion
        if self.dyteMobileClient.localUser.videoEnabled == true {
            try?self.dyteMobileClient.localUser.disableVideo()
        }else {
            self.dyteMobileClient.localUser.enableVideo()
        }
    }
    
    func toggleCamera() {
        DispatchQueue.main.async {
            self.toggleCamera(mobileClient: self.dyteMobileClient)
        }
    }
    
    private func toggleCamera(mobileClient: DyteMobileClient) {
        let videoDevices = mobileClient.localUser.getVideoDevices()
        if mobileClient.localUser.getSelectedVideoDevice()?.type == .front {
            if let device = getVideoDevice(type: .rear) {
                mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
            }
        } else if mobileClient.localUser.getSelectedVideoDevice()?.type == .rear {
            if let device = getVideoDevice(type: .front) {
                mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
            }
        }
        
        func getVideoDevice(type: VideoDeviceType) -> DyteVideoDevice? {
            for device in videoDevices {
                if device.type == type {
                    return device
                }
            }
            return nil
        }
    }
    
    func initMeetingV2(info: DyteMeetingInfoV2,completion:@escaping (_ success: Bool) -> Void) {
        self.selfMeetingInitStateCompletion = completion
        self.dyteMobileClient.doInit(dyteMeetingInfo_: info)
    }
        
    func initMeetingV1(info: DyteMeetingInfo,completion:@escaping (_ success: Bool) -> Void) {
        self.selfMeetingInitStateCompletion = completion
        dyteMobileClient.doInit(dyteMeetingInfo: info)
    }
    

    func leaveMeeting(kickAll: Bool, completion:@escaping(_ success: Bool)->Void) {
        self.selfLeaveStateCompletion = completion
        self.dyteMobileClient.leaveRoom()
        if kickAll {
            self.dyteMobileClient.participants.kickAll()
        }
    }
   
    func joinWebinarStage(completion:@escaping (_ success: Bool) -> Void) {
        self.selfWebinarJoinedStateCompletion = completion
        self.dyteMobileClient.stage.join()
    }
    
    func leaveWebinarStage(completion:@escaping (_ success: Bool) -> Void) {
        self.selfWebinarLeaveStateCompletion = completion
        self.dyteMobileClient.stage.leave()
    }
    
    func requestForPermissionToJoinWebinarStage(completion:@escaping (_ success: Bool) -> Void) {
        self.selfRequestToGetPermissionJoinedStateCompletion = completion
        self.dyteMobileClient.stage.requestAccess()
    }
    
    func cancelRequestForPermissionToJoinWebinarStage(completion:@escaping (_ success: Bool) -> Void) {
        self.selfCancelRequestToGetPermissionToJoinStageCompletion = completion
        self.dyteMobileClient.stage.cancelRequestAccess()
    }
    
    public func observeWebinarStageStatus(update:@escaping(_ status: StageStatus)->Void) {
        self.selfObserveWebinarStageStatus = update
    }
    
    public func observeRequestToJoinStage(update:@escaping()->Void) {
        self.selfObserveRequestToJoinStage = update
    }
    
    deinit{
        Self.currentInstance -= 1
        if isDebugModeOn {
            print("DyteEventSelfListner deallocing identifier \(self.identifier) \(Self.currentInstance)")
        }
    }
}

extension DyteEventSelfListner: DyteStageEventListener {

    public func onParticipantStartedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onParticipantStoppedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }

    func onParticipantRemovedFromStage(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onAddedToStage() {

        self.selfWebinarJoinedStateCompletion?(true)
    }
    
    func onPresentRequestAccepted(participant: DyteJoinedMeetingParticipant) {

    }
    
    func onPresentRequestAdded(participant: DyteJoinedMeetingParticipant) {

    }
    
    func onPresentRequestClosed(participant: DyteJoinedMeetingParticipant) {
   
    }
    
    func onPresentRequestReceived() {
        //This is called when host allow me to join stage but its depends on user action whether he want to join or not.
        if let update = self.selfObserveRequestToJoinStage {
            update()
        }
    }
    
    func onPresentRequestRejected(participant: DyteJoinedMeetingParticipant) {}
    
    func onPresentRequestWithdrawn(participant: DyteJoinedMeetingParticipant) {
        if participant.id == self.dyteMobileClient.localUser.id {
            self.selfCancelRequestToGetPermissionToJoinStageCompletion?(true)
        }
    }
    
    func onRemovedFromStage() {
        self.selfWebinarLeaveStateCompletion?(true)
    }
    
    func onStageRequestsUpdated(accessRequests: [DyteJoinedMeetingParticipant]) {}
}

extension DyteEventSelfListner: DyteSelfEventsListener {
    func onRoomMessage(type: String, payload: [String : Any]) {
        
    }
    
    func onVideoDeviceChanged(videoDevice: DyteVideoDevice) {
        
    }
    
    func onStageStatusUpdated(stageStatus: StageStatus) {
        if self.selfObserveWebinarStageStatus != nil {
            self.selfObserveWebinarStageStatus?(stageStatus)
        }
    }
    
    func onRoomMessage(message: String) {
        
    }
    
    func onUpdate(participant_ participant: DyteSelfParticipant) {
        
    }
    
    func onAudioDevicesUpdated() {

    }

    func onAudioUpdate(audioEnabled: Bool) {
        self.dyteMobileClient.localUser.audioEnabled
        self.selfAudioStateCompletion?(audioEnabled)
        self.selfObserveAudioStateCompletion?(audioEnabled)
    }
    
    func onMeetingRoomJoinedWithoutCameraPermission() {
        
    }
    
    func onMeetingRoomJoinedWithoutMicPermission() {
        
    }
    
    func onProximityChanged(isNear: Bool) {
        
    }
    
    func onRemovedFromMeeting() {
        self.selfRemovedStateCompletion?(true)
    }
    
    func onStoppedPresenting() {
        
    }
    
    func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    func onVideoUpdate(videoEnabled: Bool) {
        self.selfVideoStateCompletion?(videoEnabled)
        self.selfObserveVideoStateCompletion?(videoEnabled)
    }
    
    func onWaitListStatusUpdate(waitListStatus: WaitListStatus) {
        self.waitListStatusUpdate?(waitListStatus)
    }
    
    func onWebinarPresentRequestReceived() {
        
        func onConnectedToMeetingRoom() {
            
        }
        
        func onConnectingToMeetingRoom() {
            
        }
        
        func onDisconnectedFromMeetingRoom() {
            
        }
        
        func onMeetingRoomConnectionFailed() {
            
        }
        
    }
}

extension  DyteEventSelfListner: DyteMeetingRoomEventsListener {
    func onActiveTabUpdate(id: String, tabType: ActiveTabType) {
        self.selfTabBarSyncStateCompletion?(id)
    }

    func onConnectedToMeetingRoom() {
        
    }
    
    func onConnectingToMeetingRoom() {
        
    }
    
    func onDisconnectedFromMeetingRoom() {
        
    }
    
    func onMeetingRoomConnectionFailed() {
        
    }
    
    func onDisconnectedFromMeetingRoom(reason: String) {
        
    }
    
    func onMeetingRoomConnectionError(errorMessage: String) {
        
    }
    
    func onMeetingRoomReconnectionFailed() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance)  onMeetingRoomReconnectionFailed")
        }
        self.selfObserveReconnectionStateCompletion?(.failed)
    }
    
    func onReconnectedToMeetingRoom() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance)  onReconnectedToMeetingRoom")
        }

        self.selfObserveReconnectionStateCompletion?(.success)
    }
    
    func onReconnectingToMeetingRoom() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance) onReconnectingToMeetingRoom")
        }

        self.selfObserveReconnectionStateCompletion?(.start)
    }
    
    
    func onMeetingInitCompleted() {
        self.selfMeetingInitStateCompletion?(true)
    }
    
    func onMeetingInitFailed(exception: KotlinException) {
        self.selfMeetingInitStateCompletion?(false)
    }
    
    func onMeetingInitStarted() {
        
    }
    
    func onMeetingRoomDisconnected() {
        
    }
    
    func onMeetingRoomJoinCompleted() {

    }
    
    func onMeetingRoomJoinFailed(exception: KotlinException) {
    }
    
    func onMeetingRoomJoinStarted() {
        
    }
    
    func onMeetingRoomLeaveCompleted() {
        if let completion = self.selfLeaveStateCompletion {
            completion(true)
        }
    }
   
    func onMeetingRoomLeaveStarted() {
        
    }
}


