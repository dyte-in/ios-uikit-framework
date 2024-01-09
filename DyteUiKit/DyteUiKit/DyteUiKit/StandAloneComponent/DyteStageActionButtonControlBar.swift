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
    static func getStageStatus(status: StageStatus? = nil, mobileClient: DyteMobileClient) -> WebinarStageStatus {
        
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


class  DyteStageActionButtonControlBar: DyteControlBarButton {
    
    let stateMachine: StageButtonStateMachine
    private let mobileClient: DyteMobileClient
    private let selfListner: DyteEventSelfListner
    private let presentingViewController: UIViewController
    
    
    init(mobileClient: DyteMobileClient, buttonState: WebinarStageStatus, presentingViewController: UIViewController) {
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
    
    func updateButton(stageStatus: StageStatus) {
        self.stateMachine.forcedToSet(currentState: StageStatus.getStageStatus(status: stageStatus, mobileClient: self.mobileClient))
    }
    
    func handleRequestToJoinStage() {
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
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_join"))
            title = "Request"
        case .requestingToJoinStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_join"))
            title = "Requesting..."
        case .inRequestedStateToJoinStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_join"))
            title = "Cancel request"
        case .canJoinStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_join"))
            title = "Join stage"
        case .joiningStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_join"))
            title = "Joining..."
        case .alreadyOnStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_leave"))
            title = "Leave stage"
        case .leavingFromStage:
            image = DyteImage(image: ImageProvider.image(named: "icon_stage_leave"))
            title = "Leaving..."
        case .viewOnly:
            print("")
        }
        self.hideActivityIndicator()
        self.setDefault(image: image, title: title)
        if (state == .requestingToJoinStage || state == .leavingFromStage || state == .joiningStage) && title != nil {
            self.showActivityIndicator(title: title!)
        }
    }
    
    private var alert: WebinarAlertView?
    func showAlert(baseController: UIViewController){
        if self.alert == nil {
            let alert = WebinarAlertView(meetingClient: self.mobileClient, participant: self.mobileClient.localUser)
            alert.layer.zPosition = 1.0
            baseController.view.addSubview(alert)
            alert.btnBottom1.addTarget(self, action: #selector(alertConfirmAndJoinClick(button:)), for: .touchUpInside)
            alert.btnBottom2.addTarget(self, action: #selector(alertCancelButton(button:)), for: .touchUpInside)
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
                self.selfListner.leaveWebinarStage { success in
                    
                }
            case .inRequestedStateToJoinStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.selfListner.cancelRequestForPermissionToJoinWebinarStage { success in
                    
                }
                
            case .canRequestToJoinStage:
                self.stateMachine.handleEvent(event: .onButtonTapped)
                self.selfListner.requestForPermissionToJoinWebinarStage { success in
                    
                }
                
            default:
                print("Not handle case")
            }
    }
}
