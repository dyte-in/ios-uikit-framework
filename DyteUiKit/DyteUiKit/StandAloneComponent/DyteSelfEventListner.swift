//
//  DyteSelfEventListner.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/02/23.
//

import DyteiOSCore

class DyteEventSelfListner  {
    
    private var selfAudioStateCompletion:((Bool)->Void)?
    private var selfVideoStateCompletion:((Bool)->Void)?
    private var selfObserveVideoStateCompletion:((Bool)->Void)?
    private var selfObserveAudioStateCompletion:((Bool)->Void)?
    private var selfMeetingJoinedStateCompletion:((Bool)->Void)?
    private var selfMeetingInitStateCompletion:((Bool)->Void)?
    private var selfLeaveStateCompletion:((Bool)->Void)?
    private var selfRemovedStateCompletion:((Bool)->Void)?
    var waitListStatusUpdate:((WaitListStatus)->Void)?
    
    var dyteMobileClient: DyteMobileClient
    
    init(mobileClient: DyteMobileClient) {
        self.dyteMobileClient = mobileClient
        mobileClient.addMeetingRoomEventsListener(meetingRoomEventsListener: self)
        mobileClient.addSelfEventsListener(selfEventsListener: self)
    }
    
    func clean() {
        dyteMobileClient.removeMeetingRoomEventsListener(meetingRoomEventsListener: self)
        dyteMobileClient.removeSelfEventsListener(selfEventsListener: self)
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
    
    public func observeSelfRemoved(update:@escaping(_ success: Bool)->Void) {
        self.selfRemovedStateCompletion = update
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
        if let currentSelectedDevice: VideoDeviceType = mobileClient.localUser.getSelectedVideoDevice()?.type {
            if currentSelectedDevice == .front {
                if let device = getVideoDevice(type: .rear) {
                    mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
                }
            } else if currentSelectedDevice == .rear {
                if let device = getVideoDevice(type: .front) {
                    mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
                }
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
    
    func joinMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.selfMeetingJoinedStateCompletion = completion
        self.dyteMobileClient.joinRoom() 
    }
    
    func leaveMeeting(kickAll: Bool, completion:@escaping(_ success: Bool)->Void) {
        self.selfLeaveStateCompletion = completion
        self.dyteMobileClient.leaveRoom()
        if kickAll {
            self.dyteMobileClient.participants.kickAll()
        }
    }
    
    deinit{
        print("DyteEventSelfListner deallocing")
    }
}


extension DyteEventSelfListner: DyteSelfEventsListener {
    func onStageStatusUpdated(stageStatus: StageStatus) {
        
    }
    
    func onRoomMessage(message: String) {
        
    }
    
    func onUpdate(participant_ participant: DyteSelfParticipant) {
        
    }
    
    func onAudioDevicesUpdated() {

    }

    func onAudioUpdate(audioEnabled: Bool) {
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
        
    }
    
    func onReconnectedToMeetingRoom() {
        
    }
    
    func onReconnectingToMeetingRoom() {
        
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
        self.selfMeetingJoinedStateCompletion?(true)

    }
    
    func onMeetingRoomJoinFailed(exception: KotlinException) {
        self.selfMeetingJoinedStateCompletion?(false)
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


