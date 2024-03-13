//
//  WaitingRoomView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 24/02/23.
//

import UIKit
import DyteiOSCore

public class WaitingRoomView: UIView {
    
    var titleLabel: DyteText = {
        let label = DyteUIUTility.createLabel()
        label.numberOfLines = 0
        return label
    }()
    
    public var button: DyteButton = {
        return DyteUIUTility.createButton(text: "close")
    }()
    
    private let automaticClose: Bool
    
    private let automaticCloseTime = 2
    private let onComplete: ()->Void
   
    public  init(automaticClose: Bool, onCompletion:@escaping()->Void) {
         self.automaticClose = automaticClose
         self.onComplete = onCompletion
         super.init(frame: .zero)
         createSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func createSubviews() {
        let baseView = UIView()
        if automaticClose {
            baseView.addSubview(titleLabel)
            titleLabel.set(.sameLeadingTrailing(baseView),
                           .sameTopBottom(baseView))
            Timer.scheduledTimer(withTimeInterval: TimeInterval(automaticCloseTime), repeats: false) { timer in
                self.onComplete()
            }
        }else {
            let buttonBaseView = DyteUIUTility.wrapped(view: button)
            button.set(.centerX(buttonBaseView),
                       .leading(buttonBaseView, dyteSharedTokenSpace.space2, .greaterThanOrEqual),
                       .sameTopBottom(buttonBaseView))
            baseView.addSubViews(titleLabel,buttonBaseView)
            titleLabel.set(.sameLeadingTrailing(baseView),
                           .top(baseView))
            buttonBaseView.set(.sameLeadingTrailing(baseView), .below(titleLabel),
                               .bottom(baseView))
        }
        
        self.addSubview(baseView)
        baseView.set(.centerView(self),
                          .leading(self, dyteSharedTokenSpace.space4, .greaterThanOrEqual),
                          .top(self, dyteSharedTokenSpace.space4, .greaterThanOrEqual))
        self.button.addTarget(self, action: #selector(clickBottom(button:)), for: .touchUpInside)
    }
    
    @objc func clickBottom(button: DyteButton) {
        self.removeFromSuperview()
        self.onComplete()
    }
    
    public func show(status: WaitListStatus) {
        self.button.isHidden = true
        if status == WaitListStatus.waiting {
            self.titleLabel.text = "You are in the waiting room, the host will let you in soon."
            self.titleLabel.textColor = dyteSharedTokenColor.textColor.onBackground.shade1000

        }else if status == WaitListStatus.accepted {
            self.removeFromSuperview()
        }else if status == WaitListStatus.rejected {
            self.titleLabel.text = "Your request to join the meeting was denied."
            self.titleLabel.textColor = dyteSharedTokenColor.status.danger
            self.button.isHidden = false

        }
    }
    
    public func show(message: String) {
        self.titleLabel.text = message
    }
}
