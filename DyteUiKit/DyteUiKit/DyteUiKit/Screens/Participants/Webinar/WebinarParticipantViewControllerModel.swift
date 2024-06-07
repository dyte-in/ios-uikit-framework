//
//  ParticipantViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 15/02/23.
//

import DyteiOSCore

public class WebinarParticipantViewControllerModel {
    
    let mobileClient: DyteMobileClient
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    let dyteSelfListner: DyteEventSelfListner
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    private let searchControllerMinimumParticipant = 5
    
    required init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: mobileClient)
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)

        mobileClient.addParticipantEventsListener(participantEventsListener: self)
        mobileClient.addStageEventsListener(stageEventsListener: self)
        addObserver()
    }
    
    private func addObserver() {
        self.waitlistEventListner.participantJoinedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListner.participantRemovedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListner.participantRequestAcceptedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListner.participantRequestRejectCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
    }
    
    func acceptAll() {
        self.mobileClient.stage.grantAccessAll()
    }
    
    func acceptAllWaitingRoomRequest() {
       try? self.mobileClient.participants.acceptAllWaitingRequests()
    }
    
    func rejectAll() {
        self.mobileClient.stage.denyAccessAll()
    }
    
    private func revokeInvitationToJoinStage(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    private func participantInviteToJoinStage(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()
    
    private var completion: ((Bool)->Void)?
    
    public func load(completion:@escaping(Bool)->Void) {
       self.completion = completion
       refresh(completion: completion)
    }
    
    private func refresh(completion:@escaping(Bool)->Void) {
        self.dataSourceTableView.sections.removeAll()
        let minimumParticpantCountToShowSearchBar = searchControllerMinimumParticipant
        
        let sectionZero = self.getWaitlistSection()
        let sectionOne = self.getJoinStageRequestSection()
        let sectionTwo = self.getOnStageSection(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
        let sectionThree = self.getInCallViewers(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
        
        self.dataSourceTableView.sections.append(sectionZero)
        self.dataSourceTableView.sections.append(sectionOne)
        self.dataSourceTableView.sections.append(sectionTwo)
        self.dataSourceTableView.sections.append(sectionThree)
        completion(true)
    }
    
    func clean() {
        mobileClient.removeParticipantEventsListener(participantEventsListener: self)
        mobileClient.removeStageEventsListener(stageEventsListener: self)
        waitlistEventListner.clean()
    }
    
   
    deinit {

    }
}

extension WebinarParticipantViewControllerModel {
    
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.mobileClient.participants.waitlisted
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Waiting\(participantCount)")))
            
            for (index, participant) in waitListedParticipants.enumerated() {
                var image: DyteImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = DyteImage(url: url)
                }
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                sectionOne.insert(TableItemConfigurator<ParticipantWaitingTableViewCell,ParticipantWaitingTableViewCellModel>(model:ParticipantWaitingTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }
            
            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonWaitingTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        
        return sectionOne
    }

    private func getJoinStageRequestSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.mobileClient.stage.accessRequests
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Join stage requests\(participantCount)")))
            
            for (index, participant) in waitListedParticipants.enumerated() {
                let image: DyteImage? = nil
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                sectionOne.insert(TableItemConfigurator<OnStageWaitingRequestTableViewCell,OnStageParticipantWaitingRequestTableViewCellModel>(model:OnStageParticipantWaitingRequestTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }
            
            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonJoinStageRequestTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
                sectionOne.insert(TableItemConfigurator<RejectButtonJoinStageRequestTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Reject All")))
            }
        }
        return sectionOne
    }
   
    private func getOnStageSection(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        var arrJoinedParticipants = self.mobileClient.participants.joined
        var onStageParticipants = [DyteJoinedMeetingParticipant]()
        for participant in arrJoinedParticipants {
            if participant.stageStatus == StageStatus.onStage {
                onStageParticipants.append(participant)
            }
        }
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        if onStageParticipants.count > 0 {
            var participantCount = ""
            if onStageParticipants.count > 1 {
                participantCount = " (\(onStageParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "On stage\(participantCount)")))
            
            if onStageParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Participant")))
            }
            
            for (index, participant) in onStageParticipants.enumerated() {
                var showBottomSeparator = true
                if index == onStageParticipants.count - 1 {
                    showBottomSeparator = false
                }
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.mobileClient.localUser.permissions.host
                    
                    if hostPermission.canPinParticipant && participant.isPinned == false {
                        canShow = true
                    }
                    
                    if hostPermission.canMuteAudio && participant.audioEnabled == true {
                        canShow = true
                    }
                    
                    if hostPermission.canMuteVideo && participant.videoEnabled == true {
                        canShow = true
                    }
                    
                    if hostPermission.canKickParticipant {
                        canShow = true
                    }
                    
                    return canShow
                }
                
                var name = participant.name
                if participant.userId == mobileClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: DyteImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = DyteImage(url: url)
                }
                
                
                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel>(model:ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListner: DyteParticipantUpdateEventListner(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }
    
    private func getInCallViewers(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        var joinedParticipants = [DyteJoinedMeetingParticipant]()
        joinedParticipants.append(contentsOf: self.mobileClient.stage.viewers)
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Viewers\(participantCount)")))
            
            if joinedParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Viewers")))
                
            }
            
            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.mobileClient.localUser.permissions.host
                    
                    if self.mobileClient.localUser.canDoParticipantHostControls() || hostPermission.canAcceptRequests == true {
                        canShow = true
                    }
                     return canShow
                }
                
                var name = participant.name
                if participant.userId == mobileClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: DyteImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = DyteImage(url: url)
                }
                sectionTwo.insert(TableItemSearchableConfigurator<WebinarViewersTableViewCell,WebinarViewersTableViewCellModel>(model:WebinarViewersTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false,  participantUpdateEventListner: DyteParticipantUpdateEventListner(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }
}

extension WebinarParticipantViewControllerModel: DyteParticipantEventsListener {
    public func onAllParticipantsUpdated(allParticipants: [DyteParticipant]) {
        
    }
    
    public func onScreenShareEnded(participant_ participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onScreenShareStarted(participant_ participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    public func onScreenShareEnded(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onScreenShareStarted(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onUpdate(participants: DyteRoomParticipants) {

    }
    
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
    public func onNoActiveSpeaker() {
        
    }
    
    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onScreenSharesUpdated() {
        
    }
        
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
    
}

extension WebinarParticipantViewControllerModel: DyteStageEventListener {
    public func onParticipantStartedPresenting(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onParticipantStoppedPresenting(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onStageStatusUpdated(stageStatus: StageStatus) {
        
    }
    
    public func onParticipantRemovedFromStage(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    public func onAddedToStage() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onPresentRequestAccepted(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onPresentRequestAdded(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onPresentRequestClosed(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onPresentRequestReceived() {
        
    }
    
    public func onPresentRequestRejected(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onPresentRequestWithdrawn(participant: DyteJoinedMeetingParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onRemovedFromStage() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onStageRequestsUpdated(accessRequests: [DyteJoinedMeetingParticipant]) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    
}
