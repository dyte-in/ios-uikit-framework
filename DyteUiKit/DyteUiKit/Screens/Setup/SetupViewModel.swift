//
//  SetupViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 29/11/22.
//

import DyteiOSCore
import UIKit

protocol MeetingDelegate: AnyObject {
    func onMeetingInitFailed()
    func onMeetingInitCompleted()
}

protocol ChatDelegate {
    func refreshMessages()
}

protocol PollDelegate {
    func refreshPolls(pollMessages: [DytePollMessage])
}


protocol ParticipantsDelegate {
    func refreshList()
}

final class SetupViewModel {
    
    let dyteMobileClient: DyteMobileClient
   
    private var roomJoined:((Bool)->Void)?
    private weak var delegate: MeetingDelegate?

    var participantsDelegate : ParticipantsDelegate?
    var participants = [DyteMeetingParticipant]()
    var screenshares = [DyteMeetingParticipant]()
    
    var meetingInfoV2: DyteMeetingInfoV2?
    var meetingInfo: DyteMeetingInfo?
    let dyteSelfListner: DyteEventSelfListner
    
    init(mobileClient: DyteMobileClient, delegate: MeetingDelegate?, meetingInfoV2: DyteMeetingInfoV2?, meetingInfo: DyteMeetingInfo?) {
        self.dyteMobileClient = mobileClient
        self.delegate = delegate
        self.meetingInfoV2 = meetingInfoV2
        self.meetingInfo = meetingInfo
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        initialise()
    }
    
    func initialise() {
        if let info = meetingInfo {
            self.dyteSelfListner.initMeetingV1(info: info) { success in
                if success {
                    self.delegate?.onMeetingInitCompleted()
                }else {
                    self.delegate?.onMeetingInitFailed()
                }
            }
        }
        
        if let info = meetingInfoV2 {
            dyteSelfListner.initMeetingV2(info: info) { success in
                if success {
                    self.delegate?.onMeetingInitCompleted()
                }else {
                    self.delegate?.onMeetingInitFailed()
                }
            }
        }
    }

    
    func joinMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.dyteSelfListner.joinMeeting(completion: completion)
    }
    
    func removeListner() {
        dyteSelfListner.clean()
    }
}


