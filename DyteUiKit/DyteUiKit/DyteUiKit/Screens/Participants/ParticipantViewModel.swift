//
//  ParticipantViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 15/02/23.
//

import DyteiOSCore


struct ParticipantWaitingTableViewCellModel: BaseModel {
    func clean() {
    }
    
    var title: String
    var image: DyteImage?
    var showBottomSeparator = false
    var showTopSeparator = false
    var participant: DyteWaitlistedParticipant
}

struct OnStageParticipantWaitingRequestTableViewCellModel: BaseModel {
    var title: String
    var image: DyteImage?
    var showBottomSeparator = false
    var showTopSeparator = false
    var participant: DyteJoinedMeetingParticipant
    func clean() {
    }
}

struct ParticipantInCallTableViewCellModel: Searchable, BaseModel {
    func search(text: String) -> Bool {
        let parentText = title.lowercased()
        if parentText.hasPrefix(text) {
            return true
        }
        return false
    }
    var image: DyteImage?
    var title: String
    var showBottomSeparator = false
    var showTopSeparator = false
    var participantUpdateEventListner: DyteParticipantUpdateEventListner
    var showMoreButton: Bool
    func clean() {
        self.participantUpdateEventListner.clean()
    }
}

struct WebinarViewersTableViewCellModel: Searchable, BaseModel {
    
    func search(text: String) -> Bool {
        let parentText = title.lowercased()
        if parentText.hasPrefix(text) {
            return true
        }
        return false
    }
    var image: DyteImage?
    var title: String
    var showBottomSeparator = false
    var showTopSeparator = false
    var participantUpdateEventListner: DyteParticipantUpdateEventListner
    var showMoreButton: Bool
    func clean() {
        self.participantUpdateEventListner.clean()
    }
}


 protocol ParticipantViewControllerModelProtocol {
    var meeting: DyteMobileClient {get}
    var waitlistEventListner: DyteWaitListParticipantUpdateEventListner {get}
    var meetingEventListner: DyteMeetingEventListner {get}
    var dyteSelfListner: DyteEventSelfListner {get}
    var dataSourceTableView: DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>> { get }
    init(meeting: DyteMobileClient)
    func load(completion:@escaping(Bool)->Void)
    func acceptAll()
    func rejectAll()
}
extension ParticipantViewControllerModelProtocol {
     func moveLocalUserAtTop(section: BaseConfiguratorSection<CollectionTableConfigurator>) {
        if let indexYouParticipant = section.items.firstIndex(where: { configurator in
            if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel> {
                if configurator.model.participantUpdateEventListner.participant.userId == meeting.localUser.userId {
                    return true
                }
            }
            return false
        }) {
            if let indexFirstParticipantCell = section.items.firstIndex(where: { configurator in
                if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel> {
                    return true
                }
                return false
            }) {
                section.items.swapAt(indexYouParticipant, indexFirstParticipantCell)
            }
        }
       
    }

}


public class ParticipantViewControllerModel: ParticipantViewControllerModelProtocol{
    var dyteSelfListner: DyteEventSelfListner
    public var meeting: DyteMobileClient
    public var waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    var meetingEventListner: DyteMeetingEventListner
    private let showAcceptAllButton = true
    private let searchControllerMinimumParticipant = 5
    
    required init(meeting: DyteMobileClient) {
        self.meeting = meeting
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: meeting)
        meetingEventListner = DyteMeetingEventListner(mobileClient: meeting)
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: meeting)
        meetingEventListner.observeParticipantLeave { [weak self] participant in
            guard let self = self else {return}
            self.participantLeave(participant: participant)
        }
        
        meetingEventListner.observeParticipantJoin { [weak self] participant in
            guard let self = self else {return}
            self.participantJoin(participant: participant)
        }
        
        meetingEventListner.observeParticipantPinned {[weak self] participant in
            guard let self = self else {return}
            if let completion = self.completion {
                refresh(completion: completion)
            }
        }
        
        meetingEventListner.observeParticipantUnPinned {[weak self] participant in
            guard let self = self else {return}
            if let completion = self.completion {
                refresh(completion: completion)
            }
        }
    }
    
    func acceptAll() {
        try?self.meeting.participants.acceptAllWaitingRequests()
    }
    
    func rejectAll() {
        
    }
    
    private func participantLeave(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    private func participantJoin(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()
    
    private var completion: ((Bool)->Void)?
    
    public func load(completion:@escaping(Bool)->Void) {
            self.completion = completion
            refresh(completion: completion)
            addObserver()
    }
    
    private func refresh(completion:@escaping(Bool)->Void) {
        self.dataSourceTableView.sections.removeAll()
        let minimumParticpantCountToShowSearchBar = searchControllerMinimumParticipant
        let sectionOne = self.getWaitlistSection()
        let sectionTwo = self.getInCallSection(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
            self.dataSourceTableView.sections.append(sectionOne)
            self.dataSourceTableView.sections.append(sectionTwo)
            completion(true)
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
    deinit {
        meetingEventListner.clean()
        waitlistEventListner.clean()
    }
}

extension ParticipantViewControllerModel {
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.meeting.participants.waitlisted
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
            
            if waitListedParticipants.count > 1 && showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        return sectionOne
    }
    
    private func getInCallSection(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        let joinedParticipants = self.meeting.participants.joined
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "In Call\(participantCount)")))
            
            if joinedParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Participant")))
                
            }
            
            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.meeting.localUser.permissions.host
                    
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
                if participant.userId == meeting.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: DyteImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = DyteImage(url: url)
                }
                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel>(model:ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListner: DyteParticipantUpdateEventListner(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        self.moveLocalUserAtTop(section: sectionTwo)

        return sectionTwo
    }
    
}



public class LiveParticipantViewControllerModel: ParticipantViewControllerModelProtocol, DyteLiveStreamEventsListener {
    var dyteSelfListner: DyteEventSelfListner
    
    public func onLiveStreamEnded() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onLiveStreamEnding() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onLiveStreamErrored() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onLiveStreamStarted() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onLiveStreamStarting() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onLiveStreamStateUpdate(data: DyteLivestreamData) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onStageCountUpdated(count: Int32) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }

    public func onViewerCountUpdated(count: Int32) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    let meeting: DyteMobileClient
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    let meetingEventListner: DyteMeetingEventListner
    private let showAcceptAllButton = true //TODO: when enable then please test the functionality, for now call backs are not working
   
    required init(meeting: DyteMobileClient) {
        self.meeting = meeting
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: meeting)
        meetingEventListner = DyteMeetingEventListner(mobileClient: meeting)
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: meeting)
        meetingEventListner.observeParticipantLeave { [weak self] participant in
            guard let self = self else {return}
            self.participantLeave(participant: participant)
        }
        
        meetingEventListner.observeParticipantJoin { [weak self] participant in
            guard let self = self else {return}
            self.participantJoin(participant: participant)
        }
        meeting.addLiveStreamEventsListener(liveStreamEventsListener: self)
    }
    
    func acceptAll() {
       
        self.meeting.stage.grantAccessAll()
    }
    
    func rejectAll() {
       
        self.meeting.stage.denyAccessAll()
    }
    
    private func participantLeave(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    private func participantJoin(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()
    
    private var completion: ((Bool)->Void)?
    
    public func load(completion:@escaping(Bool)->Void) {
            self.completion = completion
            refresh(completion: completion)
            addObserver()
    }
    
    private func refresh(completion:@escaping(Bool)->Void) {
        self.dataSourceTableView.sections.removeAll()
        let minimumParticpantCountToShowSearchBar = 5
        let sectionOne = self.getWaitlistSection()
        let sectionTwo = self.getInCallSection(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
            self.dataSourceTableView.sections.append(sectionOne)
            self.dataSourceTableView.sections.append(sectionTwo)
            completion(true)
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
    deinit {
        meetingEventListner.clean()
        waitlistEventListner.clean()
    }
}

extension LiveParticipantViewControllerModel {
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.meeting.stage.accessRequests
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Waiting\(participantCount)")))
            
            for (index, participant) in waitListedParticipants.enumerated() {
                let image: DyteImage? = nil
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                sectionOne.insert(TableItemConfigurator<OnStageWaitingRequestTableViewCell,OnStageParticipantWaitingRequestTableViewCellModel>(model:OnStageParticipantWaitingRequestTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }
            
            if waitListedParticipants.count > 1 && showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
                sectionOne.insert(TableItemConfigurator<RejectButtonTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Reject All")))
            }
        }
        return sectionOne
    }
    
    private func getInCallSection(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        let joinedParticipants = self.meeting.participants.joined
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "In Call\(participantCount)")))
            
            if joinedParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Participant")))
                
            }
            
            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.meeting.localUser.permissions.host
                    
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
                if participant.userId == meeting.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: DyteImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = DyteImage(url: url)
                }
                
                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel>(model:ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListner: DyteParticipantUpdateEventListner(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        self.moveLocalUserAtTop(section: sectionTwo)
        return sectionTwo
    }
    

}




public class ParticipantWebinarViewControllerModel {
    let mobileClient: DyteMobileClient
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    let meetingEventListner: DyteMeetingEventListner
    private let showAcceptAllButton = false //TODO: when enable then please test the functionality, for now call backs are not working
   
    init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        meetingEventListner = DyteMeetingEventListner(mobileClient: mobileClient)
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: mobileClient)
        meetingEventListner.observeParticipantLeave { [weak self] participant in
            guard let self = self else {return}
            self.participantLeave(participant: participant)
        }
        
        meetingEventListner.observeParticipantJoin { [weak self] participant in
            guard let self = self else {return}
            self.participantJoin(participant: participant)
        }
    }
    
    private func participantLeave(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    private func participantJoin(participant: DyteMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()
    
    private var completion: ((Bool)->Void)?
    
    public func load(completion:@escaping(Bool)->Void) {
            self.completion = completion
            refresh(completion: completion)
            addObserver()
    }
    
    private func refresh(completion:@escaping(Bool)->Void) {
        self.dataSourceTableView.sections.removeAll()
        let minimumParticpantCountToShowSearchBar = 5
        let sectionOne = self.getWaitlistSection()
        let sectionTwo = self.getInCallSection(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
            self.dataSourceTableView.sections.append(sectionOne)
            self.dataSourceTableView.sections.append(sectionTwo)
            completion(true)
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
    deinit {
        meetingEventListner.clean()
        waitlistEventListner.clean()
    }
}

extension ParticipantWebinarViewControllerModel {
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
            if waitListedParticipants.count > 1 && showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        return sectionOne
    }
    
    private func getInCallSection(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        let joinedParticipants = self.mobileClient.participants.joined
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "InCall\(participantCount)")))
            
            if joinedParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Participant")))
                
            }
            
            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
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
                
                sectionTwo.insert(TableItemConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel>(model:ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListner: DyteParticipantUpdateEventListner(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        self.moveLocalUserAtTop(section: sectionTwo)

        return sectionTwo
    }
    
   private func moveLocalUserAtTop(section: BaseConfiguratorSection<CollectionTableConfigurator>) {
       if let indexYouParticipant = section.items.firstIndex(where: { configurator in
           if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel> {
               if configurator.model.participantUpdateEventListner.participant.userId == mobileClient.localUser.userId {
                   return true
               }
           }
           return false
       }) {
           if let indexFirstParticipantCell = section.items.firstIndex(where: { configurator in
               if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel> {
                   return true
               }
               return false
           }) {
               section.items.swapAt(indexYouParticipant, indexFirstParticipantCell)
           }
       }
      
   }

}
