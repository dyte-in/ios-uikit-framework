//
//  DyteUiKitEngine.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/01/23.
//

import Foundation
import DyteiOSCore
import UIKit

public class DyteUiKit {
        
    private  let configurationV2: DyteMeetingInfoV2?
    private  let configuration: DyteMeetingInfo?
    public let mobileClient: DyteMobileClient
    public let appTheme: AppTheme
    public let designLibrary: DesignLibrary
    
#if DEBUG
   static let isDebugModeOn = false
#else
   static let isDebugModeOn = false
#endif
    
    public  init(meetingInfo: DyteMeetingInfo) {
        mobileClient = DyteiOSClientBuilder().build()
        designLibrary = DesignLibrary.shared
        appTheme = AppTheme(designTokens: designLibrary)
        configuration = meetingInfo
        configurationV2 = nil
    }
    
    public init(meetingInfoV2: DyteMeetingInfoV2) {
        mobileClient = DyteiOSClientBuilder().build()
        designLibrary = DesignLibrary.shared
        appTheme = AppTheme(designTokens: designLibrary)
        configurationV2 = meetingInfoV2
        configuration = nil
    }
    
    public func startMeeting(completion:@escaping()->Void) -> SetupViewController {
        if let config = self.configuration {
            let controller =  SetupViewController(meetingInfo: config, mobileClient: self.mobileClient, completion: completion)
            return controller
        } else {
            let controller =  SetupViewController(meetingInfo:self.configurationV2!, mobileClient: self.mobileClient, completion: completion)
            return controller
        }
    }
}

extension DyteMobileClient {
    func getWaitlistCount() -> Int {
        return self.participants.waitlisted.count
    }
    
    func getWebinarCount() -> Int {
        return 0
    }
    
    func getPendingParticipantCount() -> Int {
        return getWebinarCount() + getWaitlistCount()
    }
}
