//
//  ParticipantViewModel.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 15/02/23.
//

import DyteiOSCore


struct ParticipantWaitingTableViewCellModel {
    var title: String
    var image: DyteImage?
    var showBottomSeparator = false
    var showTopSeparator = false
    var participant: DyteWaitlistedParticipant
}

struct ParticipantInCallTableViewCellModel: Searchable {
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
}

protocol ParticipantViewControllerModelProtocol {
    var mobileClient: DyteMobileClient {get}
    var waitlistEventListner: DyteWaitListParticipantUpdateEventListner {get}
    var meetingEventListner: DyteMeetingEventListner {get}
    var participantEventListner: ParticipantEventListner {get}
    var dataSourceTableView: DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>> { get }
    init(mobileClient: DyteMobileClient)
    func load(completion:@escaping(Bool)->Void)
    func acceptAll()
    func rejectAll()
}


public class ParticipantViewControllerModel: ParticipantViewControllerModelProtocol{
    public var mobileClient: DyteMobileClient
    public var waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    public var participantEventListner: ParticipantEventListner
    var meetingEventListner: DyteMeetingEventListner
    private let showAcceptAllButton = false //TODO: when enable then please test the functionality, for now call backs are not working
   
    required init(mobileClient: DyteMobileClient) {
        self.mobileClient = mobileClient
        meetingEventListner = DyteMeetingEventListner(mobileClient: mobileClient)
        participantEventListner = ParticipantEventListner(mobileClient: mobileClient)
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
    
    func acceptAll() {
        try?self.mobileClient.participants.acceptAllWaitingRequests()
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

extension ParticipantViewControllerModel {
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
                sectionOne.insert(TableItemConfigurator<RejectButtonTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Reject All")))
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
        return sectionTwo
    }
    

}


