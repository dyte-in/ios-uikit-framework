//
//  Constants.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 10/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import Foundation

struct Constants {
    static let errorLoadingImage = "Error Loading Image!"
    static let errorTitle = "Error!"
    static let recordingError = "Something is wrong with recording, don't worry already, we're on it!"
}

class Shared {
    static let data = Shared()
    private var chatReadCount: Int = 0
    private var viewedPollCount: Int = 0
    var delegate: DyteUiKitLifeCycle?
    var notification: DyteNotificationConfig!
    
    func getUnreadChatCount(totalMessage: Int) -> Int {
        let unreadCount = totalMessage - chatReadCount
        if unreadCount < 0 {
            return 0
        }
        return unreadCount
    }
    
    func setChatReadCount(totalMessage: Int) {
        chatReadCount = totalMessage
    }
    
    func getUnviewPollCount(totalPolls: Int) -> Int {
        let unreadCount = totalPolls - viewedPollCount
        if unreadCount < 0 {
            return 0
        }
        return unreadCount
    }
    
    func setPollViewCount(totalPolls: Int) {
        viewedPollCount = totalPolls
    }
    
    func getTotalUnreadCountPollsAndChat(totalMessage: Int, totalsPolls: Int) -> Int {
        return getUnviewPollCount(totalPolls: totalsPolls) + getUnreadChatCount(totalMessage: totalMessage)
    }
    
    func initialise() {
        chatReadCount =  0
        viewedPollCount = 0
    }
    
    func clean() {
        initialise()
    }
}
