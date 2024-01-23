//
//  MeetingViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 24/12/22.
//

import DyteiOSCore
import UIKit


protocol MeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid(forRotation: Bool)
    func refreshPluginsView()
    func activeSpeakerChanged(participant: DyteMeetingParticipant)
    func pinnedChanged(participant: DyteMeetingParticipant)
    func activeSpeakerRemoved()
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant)
    func participantJoined(participant: DyteMeetingParticipant)
    func participantLeft(participant: DyteMeetingParticipant)
    func newPollAdded(createdBy: String)
}
extension MeetingViewModelDelegate {
    func refreshMeetingGrid() {
        self.refreshMeetingGrid(forRotation: false)
    }
}

public enum DyteNotificationType {
    case Chat(message: String)
    case Poll
    case Joined
    case Leave
}

public protocol DyteNotificationDelegate: AnyObject {
    func didReceiveNotification(type: DyteNotificationType)
    func clearChatNotification()
}

public class GridCellViewModel {
    public var nameInitials: String
    public var fullName: String
    public var participant: DyteJoinedMeetingParticipant
    public  init(participant: DyteJoinedMeetingParticipant) {
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


public class ScreenShareViewModel {
    public var arrScreenShareParticipants = [ParticipantsShareControl]()
    private var dict = [String : Int]()
    public var selectedIndex: (UInt, String)?
    public init() {
    }
    public func refresh(plugins: [DytePlugin], selectedPlugin: DytePlugin?) {
        for plugin in plugins {
            if dict[plugin.id] == nil {
                arrScreenShareParticipants.append(PluginButtonModel(plugin: plugin))
                dict[plugin.id] = arrScreenShareParticipants.count - 1
            }
        }
        selectPlugin(oldId: selectedPlugin?.id)
    }
    
    public func removed(plugin: DytePlugin) {
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
    
    public func refresh(participants: [DyteJoinedMeetingParticipant]) {
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

public protocol ParticipantsShareControl {
    var image: String? {get}
    var name: String {get}
    var id: String {get}
}

public protocol PluginsButtonModelProtocol: ParticipantsShareControl {
    var plugin: DytePlugin {get}
}

public protocol ScreenSharePluginsProtocol: ParticipantsShareControl {
    var participant: DyteJoinedMeetingParticipant {get}
}


public class PluginButtonModel: PluginsButtonModelProtocol {
    public let image: String?
    public let name: String
    public let id: String
    public let plugin: DytePlugin
    
    public init(plugin: DytePlugin) {
        self.plugin = plugin
        self.id = plugin.id
        self.image = plugin.picture
        self.name = plugin.name
    }
}

public class ScreenShareModel : ScreenSharePluginsProtocol {
    public let image: String?
    public let name: String
    public let id: String
    public let nameInitials: String
    public let participant: DyteJoinedMeetingParticipant
    public init(participant: DyteJoinedMeetingParticipant) {
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
    
    public init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: dyteMobileClient)
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        self.maxParticipantOnpage = 9
        self.currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }
    
    public func clearChatNotification() {
        notificationDelegate?.clearChatNotification()
    }
    
    func trackOnGoingState() {
        
        if let participant = dyteMobileClient.participants.pinned {
            self.delegate?.pinnedChanged(participant: participant)
        }
        
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: nil)
            self.delegate?.refreshPluginsView()
        }
        
        //TODO: Do this onConnectedToMeetingRoom
        
    }
    
    func onReconnect() {
        if dyteMobileClient.participants.screenShares.count > 0 {
            self.updateScreenShareStatus()
        }
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: nil)
            self.delegate?.refreshPluginsView()
        }
        self.delegate?.refreshMeetingGrid()
    }
    
    func initialise() {
        dyteMobileClient.addParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.addPluginEventsListener(pluginEventsListener: self)
        self.dyteMobileClient.addPollEventsListener(pollEventsListener: self)

    }
    
    public func clean() {
        dyteSelfListner.clean()
        dyteMobileClient.removeParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.removePluginEventsListener(pluginEventsListener: self)
        self.dyteMobileClient.removePollEventsListener(pollEventsListener: self)
    }
    
}

extension MeetingViewModel: DytePollEventsListener {
    public func onNewPoll(poll: DytePollMessage) {
        delegate?.newPollAdded(createdBy: poll.createdBy)
        notificationDelegate?.didReceiveNotification(type: .Poll)
    }
    
    public func onPollUpdates(pollMessages: [DytePollMessage]) {
        
    }
    
    
}

extension MeetingViewModel {
    
    public func refreshActiveParticipants(pageItemCount: UInt = 0) {
        //pageItemCount tell on first page how many tiles needs to be shown to user
        self.updateActiveGridParticipants(pageItemCount: pageItemCount)
        self.delegate?.refreshMeetingGrid()
    }
    
    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        self.currentlyShowingItemOnSinglePage = pageItemCount
        self.arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
        if isDebugModeOn {
            print("Debug DyteUIKit | Current Visible Items \(arrGridParticipants.count)")
        }
    }
    
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let activeParticipants = self.dyteMobileClient.participants.active
        if isDebugModeOn {
            print("Debug DyteUIKit | Active participant count \(activeParticipants.count)")
        }
        
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
    public func onScreenSharesUpdated() {
        
    }
    

    public func onUpdate(participants: DyteRoomParticipants) {
        
    }

    public func onAllParticipantsUpdated(allParticipants: [DyteParticipant]) {

    }
    
    public func onScreenShareEnded(participant_ participant: DyteScreenShareMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit |onScreenShareEnded Participant Id \(participant.userId)")
        }
    }
    
    public func onScreenShareStarted(participant_ participant: DyteScreenShareMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onScreenShareStarted Participant Id \(participant.userId)")
        }
    }
    
    public func onScreenShareEnded(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onScreenShareEnded Participant Id \(participant.userId)")
        }
        updateScreenShareStatus()
    }
    
    public func onScreenShareStarted(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onScreenShareStarted Participant Id \(participant.userId)")
        }
        updateScreenShareStatus()
    }
    
    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onParticipantLeave Participant Id \(participant.userId)")
        }
        delegate?.participantLeft(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Leave)
    }
    
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        if isDebugModeOn {
            print("Debug DyteUIKit | onActiveParticipantsChanged")
        }
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
    }
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        self.delegate?.activeSpeakerChanged(participant: participant)
    }

    public  func onNoActiveSpeaker() {
        self.delegate?.activeSpeakerRemoved()

    }

    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {

    }
    
    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        delegate?.participantJoined(participant: participant)
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

    private func updateScreenShareStatus() {
        screenShareViewModel.refresh(participants: self.dyteMobileClient.participants.screenShares)
        self.shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        self.delegate?.refreshPluginsView()
    }
    
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
}

extension MeetingViewModel: DytePluginEventsListener {
    public func onPluginMessage(plugin: DytePlugin, eventName: String, data: Any?) {
        
    }
    
    
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
