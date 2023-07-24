//
//  DyteNotification.swift
//  DyteUiKit
//
//  Created by Shaunak Jagtap on 19/05/23.
//

import Foundation
import AVFAudio

class DyteNotification {
    var audioPlayer: AVAudioPlayer?
    
    func playNotificationSound(type: DyteNotificationType) {
        var resource = ""
        switch type {
        case .Chat, .Poll:
            resource = "notification_message"
        case .Joined, .Leave:
            resource = "notification_join"
        }
        
        do {
            let frameworkBundle =  Bundle.module
            guard let url = frameworkBundle.url(forResource: resource, withExtension: "mp3") else {return}
            
            let audioData = try Data(contentsOf: url)
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error: \(error.localizedDescription)")
            return
        }
    }
}
