//
//  DyteNotification.swift
//  DyteUiKit
//
//  Created by Shaunak Jagtap on 19/05/23.
//

import Foundation
import AVFAudio

public class DyteNotification {
    public init(){}
    public func playNotificationSound(type: DyteNotificationType) {
        var resource = ""
        switch type {
        case .Chat(_), .Poll:
            resource = "notification_message"
        case .Joined, .Leave:
            resource = "notification_join"
        }
        
        let frameworkBundle =  Bundle.resources
            guard let url = frameworkBundle.url(forResource: resource, withExtension: "mp3") else {return}
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound)
    }
}
