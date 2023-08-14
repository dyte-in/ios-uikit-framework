//
//  MeetingViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 24/12/22.
//

import DyteiOSCore


protocol MeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid()
    func refreshPluginsView()
    func meetingRecording(start: Bool)
    func activeSpeakerChanged(participant: DyteMeetingParticipant)
    func pinnedChanged(participant: DyteMeetingParticipant)
    func activeSpeakerRemoved()
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant)
    func showWaitingRoom(status: WaitListStatus)
}

enum DyteNotificationType {
    case Chat
    case Poll
    case Joined
    case Leave
}

protocol DyteNotificationDelegate: AnyObject {
    func didReceiveNotification(type: DyteNotificationType)
}

class GridCellViewModel {
    var nameInitials: String
    var fullName: String
    var participant: DyteJoinedMeetingParticipant
    init(participant: DyteJoinedMeetingParticipant) {
        self.participant = participant
        self.fullName = participant.name
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: participant.name) {
            formatter.style = .abbreviated
            self.nameInitials = formatter.string(from: components)
        }else {
            if let first = fullName.first {
                self.nameInitials = "\(first)"
            }else {
                self.nameInitials = ""
            }
        }
        
    }
}


class ScreenShareViewModel {
    var arrScreenShareParticipants = [ParticipantsShareControl]()
    private var dict = [String : Int]()
    var selectedIndex: (UInt, String)?
    
    func refresh(plugins: [DytePlugin], selectedPlugin: DytePlugin?) {
        for plugin in plugins {
            if dict[plugin.id] == nil {
                arrScreenShareParticipants.append(PluginButtonModel(plugin: plugin))
                dict[plugin.id] = arrScreenShareParticipants.count - 1
            }
        }
        selectPlugin(oldId: selectedPlugin?.id)
    }
    
    func removed(plugin: DytePlugin) {
        removePlugin(id: plugin.id)
        selectPlugin(oldId: selectedIndex?.1)
    }
    
    private func removePlugin(id: String) {
        if let index =  arrScreenShareParticipants.firstIndex(where: { item in
            return item.id == id
        }) {
            arrScreenShareParticipants.remove(at: index)
            dict[id] = nil
        }
    }
    
    func refresh(participants: [DyteScreenShareMeetingParticipant]) {
        for participant in participants {
            if dict[participant.id] == nil {
                arrScreenShareParticipants.append(ScreenShareModel(participant: participant))
                dict[participant.id] = arrScreenShareParticipants.count - 1
            }
        }
        
        func getUseLessIds() -> [String] {
            var result = [String] ()
            for participant in arrScreenShareParticipants {
                if let screenShare = participant as? ScreenShareModel {
                    // check only for ScreenShare which are now not a part of active participants are use less
                    var isIdExist = false
                    for participant in participants {
                        if screenShare.id == participant.id {
                            isIdExist = true
                            break
                        }
                    }
                    if isIdExist == false {
                        result.append(screenShare.id)
                    }
                }
            }
            return result
        }
        
        let useLessId = getUseLessIds()
        for id in useLessId {
            removePlugin(id: id)
        }
        selectPlugin(oldId: selectedIndex?.1)
    }
    
    private func selectPlugin(oldId: String?) {
        var newIndex: (UInt,String)?
        let oldId = oldId
        var index: UInt = 0
        
        for model in arrScreenShareParticipants {
            if selectedIndex == nil {
                selectedIndex = (0, model.id)
            }
            if oldId == model.id {
                newIndex = (index , model.id)
            }
            index += 1
        }
        if newIndex != nil {
            selectedIndex = newIndex
        }else {
            if arrScreenShareParticipants.count >= 1 {
                selectedIndex = (0, arrScreenShareParticipants[0].id)
            }else {
                selectedIndex = nil
            }
        }
    }
}

protocol ParticipantsShareControl {
    var image: String? {get}
    var name: String {get}
    var id: String {get}
}

protocol PluginsButtonModelProtocol: ParticipantsShareControl {
    var plugin: DytePlugin {get}
}

protocol ScreenSharePluginsProtocol: ParticipantsShareControl {
    var participant: DyteScreenShareMeetingParticipant {get}
}


class PluginButtonModel: PluginsButtonModelProtocol {
    let image: String?
    let name: String
    let id: String
    let plugin: DytePlugin
    
    init(plugin: DytePlugin) {
        self.plugin = plugin
        self.id = plugin.id
        self.image = plugin.picture
        self.name = plugin.name
    }
}

class ScreenShareModel : ScreenSharePluginsProtocol {
    let image: String?
    let name: String
    let id: String
    let nameInitials: String
    let participant: DyteScreenShareMeetingParticipant
    init(participant: DyteScreenShareMeetingParticipant) {
        self.participant = participant
        self.name = participant.name
        self.image = participant.picture
        self.id = participant.id
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: participant.name) {
            formatter.style = .abbreviated
            self.nameInitials = formatter.string(from: components)
        }else {
            if let first = name.first {
                self.nameInitials = "\(first)"
            }else {
                self.nameInitials = ""
            }
        }
    }
}

var notificationDelegate: DyteNotificationDelegate?


public final class MeetingViewModel {
    
    private let dyteMobileClient: DyteMobileClient
    let dyteSelfListner: DyteEventSelfListner
    let maxParticipantOnpage: UInt
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner

    weak var delegate: MeetingViewModelDelegate?
    var chatDelegate: ChatDelegate?
    var currentlyShowingItemOnSinglePage: UInt
    var arrGridParticipants = [GridCellViewModel]()
    var screenShareViewModel = ScreenShareViewModel()
    var shouldShowShareScreen = false
    let dyteNotification = DyteNotification()
    
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: dyteMobileClient)
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        self.maxParticipantOnpage = 9
        self.currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }
    
    func trackOnGoingState() {
        var isWaiting = false
        let waitStatus = dyteMobileClient.localUser.waitListStatus
        
        if  waitStatus == WaitListStatus.waiting {
            isWaiting = true
            self.delegate?.showWaitingRoom(status:.waiting)
        }
        
        if dyteMobileClient.recording.recordingState == .recording || dyteMobileClient.recording.recordingState == .starting {
            if isDebugModeOn {
                assert(isWaiting == false, "No functionality should be accessible from Sdk when user is in Waiting Room, Please report this to SDK owner")
            }
            self.delegate?.meetingRecording(start: true)
        }else if dyteMobileClient.recording.recordingState == .stopping {
            self.delegate?.meetingRecording(start: false)
        }
        
        if let participant = dyteMobileClient.participants.pinned {
            self.delegate?.pinnedChanged(participant: participant)
        }
        
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: nil)
            self.delegate?.refreshPluginsView()
            if isDebugModeOn {
                assert(isWaiting == false, "No functionality should be accessible from Sdk when user is in Waiting Room, Please report this to SDK owner")
            }
        }
        
    }
    
    func initialise() {
        dyteMobileClient.addParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.addPluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.addChatEventsListener(chatEventsListener: self)
    }
    
    func clean() {
        dyteSelfListner.clean()
        dyteMobileClient.removeParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.removePluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.removeChatEventsListener(chatEventsListener: self)
    }
    
}

extension MeetingViewModel {
    
    func refreshActiveParticipants(pageItemCount: UInt = 0) {
        //pageItemCount tell on first page how many tiles needs to be shown to user
        self.updateActiveGridParticipants(pageItemCount: pageItemCount)
        self.delegate?.refreshMeetingGrid()
    }
    
    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        self.currentlyShowingItemOnSinglePage = pageItemCount
        self.arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
    }
    
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let activeParticipants = self.dyteMobileClient.participants.active
        let rowCount = (pageItemCount == 0 || pageItemCount >= activeParticipants.count) ? UInt(activeParticipants.count) : min(UInt(activeParticipants.count), pageItemCount)
        if isDebugModeOn {
            print("Debug DyteUIKit | visibleItemCount \(pageItemCount) MTVM RowCount \(rowCount)")
        }
        var itemCount = 0
        var result =  [GridCellViewModel]()
        for participant in activeParticipants {
            if itemCount < rowCount {
                if participant.isPinned {
                    result.insert(GridCellViewModel(participant: participant), at: 0)
                }else {
                    result.append(GridCellViewModel(participant: participant))
                }
            } else {
                break;
            }
            itemCount += 1
        }
        return result
    }
}

extension MeetingViewModel: DyteParticipantEventsListener {
    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onScreenShareEnded(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
    }
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        print("+++++ onActiveSpeakerChanged appear \(participant.name)")
        self.delegate?.activeSpeakerChanged(participant: participant)
    }

    public  func onNoActiveSpeaker() {
        print("+++++ onNoActiveSpeaker ")
        self.delegate?.activeSpeakerRemoved()

    }

    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {

    }
    
    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {

        notificationDelegate?.didReceiveNotification(type: .Joined)
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onParticipantJoin \(participant.audioEnabled) \(participant.name) totalCount \(self.dyteMobileClient.participants.joined) participants")
        }
    }
    
    public func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {

        if isDebugModeOn {
            print("Debug DyteUIKit | Pinned changed Participant Id \(participant.userId)")
        }
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
        self.delegate?.pinnedChanged(participant: participant)
    }
    
    public func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Pinned removed Participant Id \(participant.userId)")
        }
        self.delegate?.pinnedParticipantRemoved(participant: participant)
    }

  
    public  func onScreenSharesUpdated() {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onScreenSharesUpdated(")
        }
        screenShareViewModel.refresh(participants: self.dyteMobileClient.participants.screenshares)
        self.shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        self.delegate?.refreshPluginsView()
    }
    
    
    public func onScreenShareStarted(participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onUpdate(participants: DyteRoomParticipants) {
        
    }
    
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
}


extension MeetingViewModel: DyteChatEventsListener {
    public  func onChatUpdates(messages: [DyteChatMessage]) {
        self.chatDelegate?.refreshMessages()
    }
    
    public func onNewChatMessage(message: DyteChatMessage) {
        notificationDelegate?.didReceiveNotification(type: .Chat)
    }
}

extension MeetingViewModel: DytePluginEventsListener {
    
    public func onPluginActivated(plugin: DytePlugin) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onPluginActivated(")
        }
        screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: plugin)
        self.delegate?.refreshPluginsView()
    }
    
    public func onPluginDeactivated(plugin: DytePlugin) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onPluginDeactivated(")
        }
        screenShareViewModel.removed(plugin: plugin)
        self.delegate?.refreshPluginsView()
    }
    
    public func onPluginFileRequest(plugin: DytePlugin) {
        
    }
    
    public func onPluginMessage(message: [String : Kotlinx_serialization_jsonJsonElement]) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate onPluginMessage(")
        }
    }
    
}
