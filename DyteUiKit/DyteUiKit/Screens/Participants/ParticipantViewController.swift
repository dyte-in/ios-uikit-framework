//
//  Participant.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 09/02/23.
//

import DyteiOSCore
import UIKit


let tokenColor = DesignLibrary.shared.color

let tokenSpace = DesignLibrary.shared.space

class ParticipantViewController: BaseViewController, SetTopbar, KeyboardObservable {
    let tableView = UITableView()
    let viewModel: ParticipantViewControllerModelProtocol
    var keyboardObserver: KeyboardObserver?
    private let isDebugModeOn = DyteUiKit.isDebugModeOn

    private var searchController: SearchViewController?
    
    let topBar: DyteNavigationBar = {
        let topBar = DyteNavigationBar(title: "Participants")
        return topBar
    }()
    
    public init(viewModel: ParticipantViewControllerModelProtocol) {
        self.viewModel = viewModel
        super.init(dyteMobileClient: viewModel.mobileClient)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(self.view, self.view.safeAreaInsets.top))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "GroupCall_Participant_Screen"
        self.setUpView()
        setupKeyboard()
        setUpReconnection {} success: {}
    }
    
    func setUpView() {
        self.addTopBar(dismissAnimation: true)
        setUpTableView()
        reloadScreen()
    }

   private func reloadScreen() {
        self.viewModel.load {[weak self] _ in
            guard let self = self else {return}
            self.tableView.reloadData()
        }
    }
    
    func setUpTableView() {
        self.view.addSubview(tableView)
        tableView.backgroundColor = tokenColor.background.shade1000
        tableView.set(.sameLeadingTrailing(self.view),
                      .below(topBar),
                      .bottom(self.view))
        registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }

    func registerCells(tableView: UITableView) {
        tableView.register(ParticipantInCallTableViewCell.self)
        tableView.register(ParticipantWaitingTableViewCell.self)
        tableView.register(OnStageWaitingRequestTableViewCell.self)
        tableView.register(AcceptButtonTableViewCell.self)
        tableView.register(RejectButtonTableViewCell.self)
        tableView.register(TitleTableViewCell.self)
        tableView.register(SearchTableViewCell.self)
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving {[weak self] keyboardFrame in
            guard let self = self else {return}
            self.tableView.get(.bottom)?.constant = -keyboardFrame.height
           // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {[weak self] in
            guard let self = self else {return}
            self.tableView.get(.bottom)?.constant = 0
           // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    deinit {
        if isDebugModeOn {
            print("DyteUIKit | participantView Controller deinit is calling")
        }
    }
}
extension ParticipantViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let _ = self.viewModel.dataSourceTableView.getItem(indexPath: indexPath) as? TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>  {
            self.openSearchController()
        }
    }
    
    func openSearchController() {
        let controller = SearchViewController()
        self.view.addSubview(controller.view)
        controller.view.set(.sameLeadingTrailing(self.view),
                            .below(self.topBar),
                            .bottom(self.view))
        self.searchController = controller
    }
}
extension ParticipantViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dataSourceTableView.numberOfSections()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSourceTableView.numberOfRows(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  self.viewModel.dataSourceTableView.configureCell(tableView: tableView, indexPath: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = tableView.backgroundColor
        
        if let cell = cell as? ParticipantInCallTableViewCell {
            cell.buttonMoreClick = { [weak self] button in
                guard let self = self else {return}
                if self.createMoreMenu(participantListner: cell.model.participantUpdateEventListner, indexPath: indexPath) {
                    if self.isDebugModeOn {
                        print("Debug DyteUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.moreButton.accessibilityIdentifier = "InCall_ThreeDots_Button" 
           
        } else if let cell = cell as? ParticipantWaitingTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.waitlistEventListner.rejectWaitingRequest(participant: cell.model.participant)
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.waitlistEventListner.acceptWaitingRequest(participant: cell.model.participant)
                
            }
        } else if let cell = cell as? OnStageWaitingRequestTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.mobileClient.stage.denyAccess(id: cell.model.participant.id)
                button.hideActivityIndicator()
                self.reloadScreen()
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.mobileClient.stage.grantAccess(id: cell.model.participant.id)
                button.hideActivityIndicator()
                self.reloadScreen()
            }
        } else if let cell = cell as? AcceptButtonTableViewCell {
            cell.button.hideActivityIndicator()
            cell.buttonClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.acceptAll()
                button.hideActivityIndicator()

                self.reloadScreen()
            }
        } else if let cell = cell as? RejectButtonTableViewCell {
            cell.button.hideActivityIndicator()
            cell.buttonClick = { [weak self] button in
                guard let self = self else {return}
                self.viewModel.rejectAll()
                self.reloadScreen()
            }
        }
        return cell
    }
    
    private func createMoreMenu(participantListner: DyteParticipantUpdateEventListner, indexPath: IndexPath)-> Bool {
        var menus = [MenuType]()
        let participant = participantListner.participant
        let hostPermission = self.viewModel.mobileClient.localUser.permissions.host
        
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
        
        if hostPermission.canKickParticipant && participant != self.viewModel.mobileClient.localUser {
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


