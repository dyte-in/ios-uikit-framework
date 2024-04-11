//
//  SearchViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/02/23.
//

import UIKit
import DyteiOSCore
class SearchViewControllerModel {
    
    init(sections:[BaseConfiguratorSection<CollectionTableSearchConfigurator>]) {
        dataSourceTableView = DataSourceSearchStandard(sections: sections)
    }
    
    var dataSourceTableView: DataSourceSearchStandard<BaseConfiguratorSection<CollectionTableSearchConfigurator>>!

    func search(text: String, completion: ()->Void) {
        if text.isEmpty == true {
            self.dataSourceTableView.set(sections: self.dataSourceTableView.originalSections)
        }else {
            var sections =  [BaseConfiguratorSection<CollectionTableSearchConfigurator>]()
            for section in self.dataSourceTableView.originalSections {
                let filterSection =  BaseConfiguratorSection<CollectionTableSearchConfigurator>()
                for item in section.items {
                    if item.search(text: text) == true {
                        filterSection.insert(item)
                    }
                }
                if filterSection.items.count > 0 {
                    sections.append(filterSection)
                }
            }
            self.dataSourceTableView.set(sections: sections)
        }
        completion()

    }
}


public class SearchViewController: UIViewController, KeyboardObservable {
    
    let tableView = UITableView()
    let viewModel: SearchViewControllerModel
    var keyboardObserver: KeyboardObserver?
    
    let searchBar = {
        let searchBar = UISearchBar()
        searchBar.changeText(color: dyteSharedTokenColor.textColor.onBackground.shade700)
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }()
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner
    let meeting : DyteMobileClient
    let completion: ()->Void
    init(meeting: DyteMobileClient, originalItems: [BaseConfiguratorSection<CollectionTableSearchConfigurator>], completion: @escaping(()->Void)) {
        self.viewModel = SearchViewControllerModel(sections: originalItems)
        self.meeting = meeting
        self.completion = completion
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: meeting)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpView()
        setupKeyboard()
        searchBar.becomeFirstResponder()
        addObserver()
    }
     
    
    private func addObserver() {
        self.waitlistEventListner.participantJoinedCompletion = { [weak self] partipant in
            guard let self = self else {return}
            self.reloadScreen()
        }
        self.waitlistEventListner.participantRemovedCompletion = { [weak self] partipant in
            guard let self = self else {return}
            self.reloadScreen()
        }
        self.waitlistEventListner.participantRequestAcceptedCompletion = { [weak self] partipant in
            guard let self = self else {return}
            self.reloadScreen()
        }
        self.waitlistEventListner.participantRequestRejectCompletion = { [weak self] partipant in
            guard let self = self else {return}
            self.reloadScreen()
        }
    }
    
    func setUpView() {
        searchBar.delegate = self
        self.view.backgroundColor = dyteSharedTokenColor.background.shade1000
        self.view.addSubview(searchBar)
        searchBar.set(.top(self.view),
                      .sameLeadingTrailing(self.view))
        setUpTableView()
    }

    func setUpTableView() {
        self.view.addSubview(tableView)
        tableView.backgroundColor = dyteSharedTokenColor.background.shade1000
        tableView.set(.sameLeadingTrailing(self.view),
                      .below(self.searchBar),
                      .bottom(self.view))
        registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    func registerCells(tableView: UITableView) {
        tableView.register(ParticipantWaitingTableViewCell.self)
        tableView.register(OnStageWaitingRequestTableViewCell.self)
        tableView.register(ParticipantInCallTableViewCell.self)
        tableView.register(WebinarViewersTableViewCell.self)
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { keyboardFrame in
            self.tableView.get(.bottom)?.constant = -keyboardFrame.height
           // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {
            self.tableView.get(.bottom)?.constant = 0
           // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
}


extension SearchViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.search(text: searchText) {
            self.tableView.reloadData()
        }
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.removeFromSuperview()
        waitlistEventListner.clean()
        self.completion()
    }
}

extension SearchViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dataSourceTableView.numberOfSections()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSourceTableView.numberOfRows(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  self.viewModel.dataSourceTableView.configureCell(tableView: tableView, indexPath: indexPath)
        cell.backgroundColor = tableView.backgroundColor
        if let cell = cell as? ParticipantInCallTableViewCell {
            cell.buttonMoreClick = { [weak self] button in
                guard let self = self else {return}
                self.searchBar.resignFirstResponder()

                if self.createMoreMenu(participantListner: cell.model.participantUpdateEventListner, indexPath: indexPath) {
                    if self.isDebugModeOn {
                        print("Debug DyteUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.setPinView(isHidden: !cell.model.participantUpdateEventListner.participant.isPinned)
           
        }
        else if let cell = cell as? ParticipantWaitingTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.waitlistEventListner.rejectWaitingRequest(participant: cell.model.participant)
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.waitlistEventListner.acceptWaitingRequest(participant: cell.model.participant)
            }
            cell.setPinView(isHidden: true)

        }
        else if let cell = cell as? WebinarViewersTableViewCell {
            cell.buttonMoreClick = { [weak self] button in
                guard let self = self else {return}
                self.searchBar.resignFirstResponder()
                if self.createMoreMenuForViewers(participantListner: cell.model.participantUpdateEventListner, indexPath: indexPath) {
                    if self.isDebugModeOn {
                        print("Debug DyteUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.setPinView(isHidden: !cell.model.participantUpdateEventListner.participant.isPinned)
        }
        else if let cell = cell as? OnStageWaitingRequestTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.meeting.stage.denyAccess(id: cell.model.participant.id)
                button.hideActivityIndicator()
                self.reloadScreen()
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.meeting.stage.grantAccess(id: cell.model.participant.id)
                button.hideActivityIndicator()
                self.reloadScreen()
            }
            cell.setPinView(isHidden: !cell.model.participant.isPinned)

        }
        return cell
    }
    
    func reloadScreen() {
        self.tableView.reloadData()
    }
    
    private func createMoreMenuForViewers(participantListner: DyteParticipantUpdateEventListner, indexPath: IndexPath)-> Bool {
        var menus = [MenuType]()
        let participant = participantListner.participant
        let hostPermission = self.meeting.localUser.permissions.host
        
        //TODO: Add below code inside condition of whether I had already allowed or not.
        menus.append(.allowToJoinStage)
        
        if hostPermission.canKickParticipant && participant != self.meeting.localUser {
            menus.append(.kick)
        }
        
        if menus.count < 1 {
            return false
        }
        menus.append(contentsOf: [.cancel])
        
        let moreMenu = DyteMoreMenu(title: participant.name, features: menus, onSelect: { [weak self] menuType in
            guard let self = self else {return}
            switch menuType {
            
            case .allowToJoinStage:
                self.meeting.stage.grantAccess(id: participant.id)
                
            case .denyToJoinStage:
               print("Don't know ")
                
            case .kick:
                try?participant.kick()
                
            case .cancel:
                print("Not Supported for now")
                
            default:
                print("No need to handle others for now")
            }
        })
        moreMenu.show(on: view)
        return true
    }
    
    private func createMoreMenu(participantListner: DyteParticipantUpdateEventListner, indexPath: IndexPath)-> Bool {
        var menus = [MenuType]()
        let participant = participantListner.participant
        let hostPermission = self.meeting.localUser.permissions.host
        
        menus.append(.removeFromStage)
        if hostPermission.canPinParticipant {
            if participant.isPinned == false {
                menus.append(.pin)
            }else {
                menus.append(.unPin)
            }
        }
        
        if hostPermission.canMuteAudio && participant.audioEnabled == true {
            menus.append(.muteAudio)
        }
        
        if hostPermission.canMuteVideo && participant.videoEnabled == true {
            menus.append(.muteVideo)
        }
        
        if hostPermission.canKickParticipant && participant != self.meeting.localUser {
            menus.append(.kick)
        }
        
        if menus.count < 1 {
            return false
        }
        menus.append(contentsOf: [.cancel])
        
        let moreMenu = DyteMoreMenu(title: participant.name, features: menus, onSelect: { [weak self] menuType in
            guard let self = self else {return}
            switch menuType {
            case .pin:
                try?participant.pin()
            case .unPin:
                try?participant.unpin()
                
            case .muteAudio:
                try?participant.disableAudio()
            case .muteVideo:
                try?participant.disableVideo()
            case .removeFromStage:
                self.meeting.stage.kick(id: participant.id)
            case .kick:
                try?participant.kick()
                
            case .cancel:
                print("Not Supported for now")
                
            default:
                print("No need to handle others for now")
            }
        })
        moreMenu.show(on: view)
        return true
    }

    
}
