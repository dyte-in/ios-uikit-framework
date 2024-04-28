//
//  DyteSelfEventListner.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/02/23.
//

import DyteiOSCore
import UIKit

public class DyteEventSelfListner  {
    private static var currentInstance = 0
    public enum Reconnection {
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
    private var observeSelfPermissionChanged:(()->Void)?
    private var selfWebinarJoinedStateCompletion:((Bool)->Void)?
    private var selfWebinarLeaveStateCompletion:((Bool)->Void)?
    private var selfRequestToGetPermissionJoinedStateCompletion:((Bool)->Void)?
    private var selfCancelRequestToGetPermissionToJoinStageCompletion:((Bool)->Void)?
    private var selfMeetingInitStateCompletion:((Bool, String?)->Void)?
    private var selfLeaveStateCompletion:((Bool)->Void)?
    private var selfRemovedStateCompletion:((Bool)->Void)?
    private var selfTabBarSyncStateCompletion:((String)->Void)?
    private var selfObserveReconnectionStateCompletion:((Reconnection)->Void)?

    var waitListStatusUpdate:((WaitListStatus)->Void)?
    
    var dyteMobileClient: DyteMobileClient
    let identifier: String
    public init(mobileClient: DyteMobileClient, identifier: String = "Default") {
        self.identifier = identifier
        self.dyteMobileClient = mobileClient
        mobileClient.addMeetingRoomEventsListener(meetingRoomEventsListener: self)
        mobileClient.addSelfEventsListener(selfEventsListener: self)
        mobileClient.addStageEventsListener(stageEventsListener: self)
        Self.currentInstance += 1
    }
    
    public func clean() {
        dyteMobileClient.removeMeetingRoomEventsListener(meetingRoomEventsListener: self)
        dyteMobileClient.removeSelfEventsListener(selfEventsListener: self)
        dyteMobileClient.removeStageEventsListener(stageEventsListener: self)

    }
    
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
   public func toggleLocalAudio(completion: @escaping(_ isEnabled: Bool)->Void) {
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
    
    public func toggleLocalVideo(completion: @escaping(_ isEnabled: Bool)->Void) {
        self.selfVideoStateCompletion = completion
        if self.dyteMobileClient.localUser.videoEnabled == true {
            try?self.dyteMobileClient.localUser.disableVideo()
        }else {
            self.dyteMobileClient.localUser.enableVideo()
        }
    }
    
    public func isCameraPermissionGranted(alertPresentingController: UIViewController? = DyteUIUTility.getTopViewController()) -> Bool {
        if !self.dyteMobileClient.localUser.isCameraPermissionGranted {
            
            if let alertContoller = alertPresentingController {
                let alert = UIAlertController(title: "Camera", message: "Camera access is necessary to use this app.\n Please click settings to change the permission.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                    // Handle cancel action if needed
                }))
                
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }))
                
                alertContoller.present(alert, animated: true, completion: nil)
            }
            
            return false
        } else {
            return true
        }
    }
    
    public func isMicrophonePermissionGranted(alertPresentingController: UIViewController? = DyteUIUTility.getTopViewController() ) -> Bool {
        if !self.dyteMobileClient.localUser.isMicrophonePermissionGranted {
            if let alertController = alertPresentingController {
                let alert = UIAlertController(title: "Microphone", message: "Microphone access is necessary to use this app.\n Please click settings to change the permission.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                    // Handle cancel action if needed
                }))
                
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }))
                
                alertController.present(alert, animated: true, completion: nil)
            }
            return false
        } else {
            return true
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
    
    func initMeetingV2(info: DyteMeetingInfoV2,completion:@escaping (_ success: Bool, _ message: String?) -> Void) {
        self.selfMeetingInitStateCompletion = completion
        self.dyteMobileClient.doInit(dyteMeetingInfo_: info)
    }
        
    func initMeetingV1(info: DyteMeetingInfo,completion:@escaping (_ success: Bool, _ message: String?) -> Void) {
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
    
    public func observeSelfPermissionChanged(update:@escaping()->Void) {
        self.observeSelfPermissionChanged = update
    }
    
    deinit{
        Self.currentInstance -= 1
        if isDebugModeOn {
            print("DyteEventSelfListner deallocing identifier \(self.identifier) \(Self.currentInstance)")
        }
    }
}

extension DyteEventSelfListner: DyteStageEventListener {
    public func onPresentRequestRejected(participant: DyteJoinedMeetingParticipant) {
        
    }
    

    public func onParticipantStartedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onParticipantStoppedPresenting(participant: DyteJoinedMeetingParticipant) {
        
    }

    public func onParticipantRemovedFromStage(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onAddedToStage() {

        self.selfWebinarJoinedStateCompletion?(true)
    }
    
    public func onPresentRequestAccepted(participant: DyteJoinedMeetingParticipant) {

    }
    
    public func onPresentRequestAdded(participant: DyteJoinedMeetingParticipant) {

    }
    
    public func onPresentRequestClosed(participant: DyteJoinedMeetingParticipant) {
   
    }
    
    public func onPresentRequestReceived() {
        //This is called when host allow me to join stage but its depends on user action whether he want to join or not.
        if let update = self.selfObserveRequestToJoinStage {
            update()
        }
    }
    
    public func onPresentRequestWithdrawn(participant: DyteJoinedMeetingParticipant) {
        if participant.id == self.dyteMobileClient.localUser.id {
            self.selfCancelRequestToGetPermissionToJoinStageCompletion?(true)
        }
    }
    
    public func onRemovedFromStage() {
        self.selfWebinarLeaveStateCompletion?(true)
    }
    
    public func onStageRequestsUpdated(accessRequests: [DyteJoinedMeetingParticipant]) {}
}

extension DyteEventSelfListner: DyteSelfEventsListener {
   
    public func onPermissionsUpdated(permission: SelfPermissions) {
        self.observeSelfPermissionChanged?()
    }
    

    public func onScreenShareStartFailed(reason: String) {
        
    }
    
    public func onScreenShareStarted() {
        
    }
    
    public func onScreenShareStopped() {
        
    }
    
    public func onRoomMessage(type: String, payload: [String : Any]) {
        
    }
    
    public func onVideoDeviceChanged(videoDevice: DyteVideoDevice) {
        
    }
    
    public func onStageStatusUpdated(stageStatus: StageStatus) {
        self.selfObserveWebinarStageStatus?(stageStatus)
    }
    
    func onRoomMessage(message: String) {
        
    }
    
    public func onUpdate(participant_ participant: DyteSelfParticipant) {
        
    }
    
    public func onAudioDevicesUpdated() {

    }

    public  func onAudioUpdate(audioEnabled: Bool) {
        self.selfAudioStateCompletion?(audioEnabled)
        self.selfObserveAudioStateCompletion?(audioEnabled)
    }
    
    public func onMeetingRoomJoinedWithoutCameraPermission() {
        
    }
    
    public func onMeetingRoomJoinedWithoutMicPermission() {
        
    }
    
    public func onProximityChanged(isNear: Bool) {
        
    }
    
    public func onRemovedFromMeeting() {
        self.selfRemovedStateCompletion?(true)
    }
    
    func onStoppedPresenting() {
        
    }
    
    func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    public func onVideoUpdate(videoEnabled: Bool) {
        self.selfVideoStateCompletion?(videoEnabled)
        self.selfObserveVideoStateCompletion?(videoEnabled)
    }
    
    public func onWaitListStatusUpdate(waitListStatus: WaitListStatus) {
        self.waitListStatusUpdate?(waitListStatus)
    }
    
    func onWebinarPresentRequestReceived() {
        
    }
}

extension  DyteEventSelfListner: DyteMeetingRoomEventsListener {
    public func onActiveTabUpdate(id: String, tabType: ActiveTabType) {
        self.selfTabBarSyncStateCompletion?(id)
    }

    public func onConnectedToMeetingRoom() {
        
    }
    
    public func onConnectingToMeetingRoom() {
        
    }
    
    public func onDisconnectedFromMeetingRoom() {
        
    }
    
    public func onMeetingRoomConnectionFailed() {
        
    }
    
    func onDisconnectedFromMeetingRoom(reason: String) {
        
    }
    
    func onMeetingRoomConnectionError(errorMessage: String) {
        
    }
    
    public func onMeetingRoomReconnectionFailed() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance)  onMeetingRoomReconnectionFailed")
        }
        self.selfObserveReconnectionStateCompletion?(.failed)
    }
    
    public func onReconnectedToMeetingRoom() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance)  onReconnectedToMeetingRoom")
        }

        self.selfObserveReconnectionStateCompletion?(.success)
    }
    
    public func onReconnectingToMeetingRoom() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteEventSelfListner \(Self.currentInstance) onReconnectingToMeetingRoom")
        }

        self.selfObserveReconnectionStateCompletion?(.start)
    }
    
    
    public func onMeetingInitCompleted() {
        self.selfMeetingInitStateCompletion?(true, "")
    }
    
    public  func onMeetingInitFailed(exception: KotlinException) {
        self.selfMeetingInitStateCompletion?(false, exception.message)
    }
    
    public func onMeetingInitStarted() {
        
    }
    
    public func onMeetingRoomDisconnected() {
        
    }
    
    public func onMeetingRoomJoinCompleted() {

    }
    
    public func onMeetingRoomJoinFailed(exception: KotlinException) {
    }
    
    public func onMeetingRoomJoinStarted() {
        
    }
    
    public func onMeetingRoomLeaveCompleted() {
        if let completion = self.selfLeaveStateCompletion {
            completion(true)
        }
    }
   
    public func onMeetingRoomLeaveStarted() {
        
    }
}


