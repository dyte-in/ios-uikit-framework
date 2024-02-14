//
//  DyteStageActionButtonControlBar.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 19/07/23.
//

import DyteiOSCore
import UIKit

class StageButtonStateMachine {
    
    enum Event {
        case onAccepted
        case onRejected
        case onSuccess
        case leaveSuccessFullWithCanRequest
        case leaveSuccessFullWithJoinStage
        case onFail
        case onButtonTapped
    }
    
    var currentState: WebinarStageStatus {
        didSet {
            self.stateTransition?(oldValue,currentState)
        }
    }
    
    private let possibleState : [WebinarStageStatus: Set<WebinarStageStatus>] =
    [.canRequestToJoinStage: [.requestingToJoinStage],
     .requestingToJoinStage: [.inRequestedStateToJoinStage,.canRequestToJoinStage],
     .inRequestedStateToJoinStage: [.canRequestToJoinStage, .canJoinStage],
     .canJoinStage: [.joiningStage],
     .joiningStage: [.canJoinStage, .alreadyOnStage],
     .alreadyOnStage: [.leavingFromStage],
     .leavingFromStage: [.alreadyOnStage, .canJoinStage, .canRequestToJoinStage],
     .viewOnly: []
    ]
    
    private var stateTransition: ((WebinarStageStatus, WebinarStageStatus) -> Void)?
   
    init(state: WebinarStageStatus) {
        self.currentState = state
    }
    
    func forcedToSet(currentState: WebinarStageStatus) {
        self.currentState = currentState
    }
    
    func start() {
        self.stateTransition?(currentState,currentState)
    }
    
    func setTransition(update: @escaping(WebinarStageStatus, WebinarStageStatus)-> Void) {
        self.stateTransition = update
    }
    
    func removeTransition() {
        self.stateTransition = nil

    }
    
   @discardableResult private func transition(toState: WebinarStageStatus) -> Bool {
        if let nextState = canTransition(fromState: self.currentState, toState: toState) {
            self.currentState = nextState
            return true
        }
        return false
    }
    
    private func canTransition(fromState: WebinarStageStatus, toState: WebinarStageStatus) -> WebinarStageStatus? {
        if let possibleState = possibleState[fromState], possibleState.contains(toState) {
            return toState
        }
        return nil
    }
    
    func  handleEvent(event: Event) {
        switch (currentState, event) {
        case (.canRequestToJoinStage, .onButtonTapped):
            transition(toState: .requestingToJoinStage)
       
        case (.requestingToJoinStage, .onSuccess):
            transition(toState: .inRequestedStateToJoinStage)
        case (.requestingToJoinStage, .onFail):
            transition(toState: .canRequestToJoinStage)
       
        case (.inRequestedStateToJoinStage, .onRejected):
            transition(toState: .canRequestToJoinStage)
        case (.inRequestedStateToJoinStage, .onAccepted):
            transition(toState: .canJoinStage)
            
        case (.canJoinStage, .onButtonTapped):
            transition(toState: .joiningStage)
            
        case (.joiningStage, .onFail):
            transition(toState: .canJoinStage)
        case (.joiningStage, .onSuccess):
            transition(toState: .alreadyOnStage)
            
        case (.alreadyOnStage, .onButtonTapped):
            transition(toState: .leavingFromStage)
            
        case (.leavingFromStage, .onFail):
            transition(toState: .alreadyOnStage)
        case (.leavingFromStage, .leaveSuccessFullWithJoinStage):
            transition(toState: .canJoinStage)
        case (.leavingFromStage, .leaveSuccessFullWithCanRequest):
            transition(toState: .canRequestToJoinStage)
        default:
            print("Invalid \(event) happen on current state \(self.currentState)")
            
        }
        
    }
}

extension StageStatus {
    
   public static func getStageStatus(status: StageStatus? = nil, mobileClient: DyteMobileClient) -> WebinarStageStatus {
        
        let state = status ?? mobileClient.stage.stageStatus
      
        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = mobileClient.localUser.permissions.media.video
            let audioPermission = mobileClient.localUser.permissions.media.audioPermission
            if videoPermission == DyteMediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            }
            else if videoPermission == DyteMediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == DyteMediaPermission.notAllowed && audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
        case .rejectedToJoinStage:
            return .canRequestToJoinStage
        case .onStage:
            return .alreadyOnStage
        case .requestedToJoinStage:
            return .inRequestedStateToJoinStage
            
        default:
            print("Unknown case")
        }
        return .viewOnly
    }
}

public protocol DyteStageActionButtonControlBarDataSource {
    func getImage(for stageStatus: WebinarStageStatus) -> DyteImage?
    func getTitle(for stageStatus: WebinarStageStatus) -> String?
    func getAlertView() -> ConfigureWebinerAlertView
}

public protocol ConfigureWebinerAlertView: UIView {
    var confirmAndJoinButton: DyteButton {get }
    var cancelButton: DyteButton {get }
}

public class  DyteStageActionButtonControlBar: DyteControlBarButton {
    let stateMachine: StageButtonStateMachine
    private let mobileClient: DyteMobileClient
    private let selfListner: DyteEventSelfListner
    private let presentingViewController: UIViewController
    public var dataSource: DyteStageActionButtonControlBarDataSource?
    
    public init(mobileClient: DyteMobileClient, buttonState: WebinarStageStatus, presentingViewController: UIViewController) {
        self.mobileClient = mobileClient
        self.presentingViewController = presentingViewController
        self.selfListner = DyteEventSelfListner(mobileClient: mobileClient)
        stateMachine = StageButtonStateMachine(state: buttonState)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Join stage")
        self.addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
    }
    
    public func addObserver() {
        stateMachine.setTransition(){ [weak self] fromState, currentState in
            guard let self = self else {return}
            self.showState(state: currentState)
        }
        stateMachine.start()
    }
    
    public func updateButton(stageStatus: StageStatus) {
        self.stateMachine.forcedToSet(currentState: StageStatus.getStageStatus(status: stageStatus, mobileClient: self.mobileClient))
    }
    
    public func handleRequestToJoinStage() {
        self.stateMachine.forcedToSet(currentState: .joiningStage)
        self.showAlert(baseController: self.presentingViewController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
   override func clean() {
        self.stateMachine.removeTransition()
        self.selfListner.clean()
        removeAlertView()
    }
    
    deinit {
        clean()
        print("******* stageButton Deinit is calling")
    }
    
    private func showState(state: WebinarStageStatus) {
        var image: DyteImage? = nil
        var title: String? = nil
      
        switch state {
        case .canRequestToJoinStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = self.dataSource?.getTitle(for: state) ?? "Request"
        case .requestingToJoinStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = self.dataSource?.getTitle(for: state) ?? "Requesting..."
        case .inRequestedStateToJoinStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = self.dataSource?.getTitle(for: state) ?? "Cancel request"
        case .canJoinStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = self.dataSource?.getTitle(for: state) ?? "Join stage"
        case .joiningStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = self.dataSource?.getTitle(for: state) ?? "Joining..."
        case .alreadyOnStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_leave")))
            title = self.dataSource?.getTitle(for: state) ?? "Leave stage"
        case .leavingFromStage:
            image = self.getImage(state: state, defaultImage: DyteImage(image: ImageProvider.image(named: "icon_stage_leave")))
            title = self.dataSource?.getTitle(for: state) ?? "Leaving..."
        case .viewOnly:
            print("")
        }
        self.hideActivityIndicator()
        self.setDefault(image: image, title: title)
        if (state == .requestingToJoinStage || state == .leavingFromStage || state == .joiningStage) && title != nil {
            self.showActivityIndicator(title: title!)
        }
        
        if (state == .alreadyOnStage) {
            self.isSelected = true
        }
    }
    
    private func getImage(state: WebinarStageStatus, defaultImage: DyteImage) -> DyteImage {
        if let image =  self.dataSource?.getImage(for: state) {
            print("image returned for stage \(state)")
            return image
        }
        return defaultImage
    }
    
    private var alert: ConfigureWebinerAlertView?
   
    func showAlert(baseController: UIViewController) {
        if self.alert == nil {
            let alert = self.dataSource?.getAlertView() ?? WebinarAlertView(meetingClient: self.mobileClient, participant: self.mobileClient.localUser)
            alert.layer.zPosition = 1.0
            baseController.view.addSubview(alert)
            alert.confirmAndJoinButton.addTarget(self, action: #selector(alertConfirmAndJoinClick(button:)), for: .touchUpInside)
            alert.cancelButton.addTarget(self, action: #selector(alertCancelButton(button:)), for: .touchUpInside)
            alert.set(.fillSuperView(baseController.view))
            self.alert = alert
            Shared.data.delegate?.webinarJoinStagePopupDidShow()
        }
    }
    
    private func removeAlertView() {
        self.alert?.removeFromSuperview()
        self.alert = nil
    }
    
    @objc open func alertConfirmAndJoinClick(button: DyteJoinButton) {
        removeAlertView()
        Shared.data.delegate?.webinarJoinStagePopupDidHide(click: .confirmAndJoin)
        self.selfListner.joinWebinarStage { success in
        }
    }
    
    @objc open func alertCancelButton(button: DyteJoinButton) {
        removeAlertView()
        Shared.data.delegate?.webinarJoinStagePopupDidHide(click: .cancel)
        self.stateMachine.handleEvent(event: .onFail)
    }
    
    @objc func click(button: DyteControlBarButton) {
         let currentState = self.stateMachine.currentState
            switch currentState {
                
            case .canJoinStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.showAlert(baseController: self.presentingViewController)
                
            case .alreadyOnStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.selfListner.leaveWebinarStage { success in }
                
            case .inRequestedStateToJoinStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.selfListner.cancelRequestForPermissionToJoinWebinarStage { success in }
                
            case .canRequestToJoinStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.selfListner.requestForPermissionToJoinWebinarStage { success in }
                
            default:
                print("Not handle case")
            }
    }
}

