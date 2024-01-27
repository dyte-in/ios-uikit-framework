//
//  DyteBaseViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 16/01/24.
//

import UIKit
import DyteiOSCore

open class DyteBaseViewController: UIViewController, AdaptableUI {
    let dyteSelfListner: DyteEventSelfListner!
    public let meeting: DyteMobileClient
    private var waitingRoomView: WaitingRoomView?
    public var portraitConstraints = [NSLayoutConstraint]()
    public var landscapeConstraints = [NSLayoutConstraint]()
    
   public init(dyteMobileClient: DyteMobileClient) {
        self.meeting = dyteMobileClient
        dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    public func setUpReconnection(failed: @escaping()->Void, success: @escaping()->Void) {
        dyteSelfListner.observeMeetingReconnectionState { [weak self] state in
            guard let self = self else {return}
            switch state {
            case .failed:
                self.view.removeToast()
                let retryAction = UIAlertAction(title: "ok", style: .default) { action in
                    failed()
                }
                DyteUIUTility.displayAlert(alertTitle: "Connection Lost!", message: "Please try again later", actions: [retryAction])
            case .success:
                success()
                self.view.showToast(toastMessage: "Connection Restored", duration: 2.0)
            case .start:
                self.view.showToast(toastMessage: "Reconnecting...", duration: -1)
            }
        }
    }
    
    public func addWaitingRoom(completion:@escaping()->Void) {
        self.dyteSelfListner.waitListStatusUpdate = { [weak self] status in
            guard self != nil else {return}
            let callBack : ()-> Void = {
                completion()
            }
            showWaitingRoom(status: status, completion: callBack)
        }
        
        func showWaitingRoom(status: WaitListStatus, completion: @escaping()->Void) {
           waitingRoomView?.removeFromSuperview()
           if status != .none {
               let waitingView = WaitingRoomView(automaticClose: false, onCompletion: { [weak self] in
                   guard self != nil else {return}
                   completion()
               })
               waitingView.accessibilityIdentifier = "WaitingRoom_View"
               waitingView.backgroundColor = self.view.backgroundColor
               self.view.addSubview(waitingView)
               waitingView.set(.fillSuperView(self.view))
               self.view.endEditing(true)
               waitingRoomView = waitingView
               waitingView.show(status: status)
           }
       }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        applyConstraintAsPerOrientation()
    }
}
