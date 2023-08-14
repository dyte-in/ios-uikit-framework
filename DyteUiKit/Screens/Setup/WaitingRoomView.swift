//
//  WaitingRoomView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 24/02/23.
//

import UIKit
import DyteiOSCore

class WaitingRoomView: UIView {
    
    var titleLabel: DyteText = {
        let label = UIUTility.createLabel()
        label.numberOfLines = 0
        return label
    }()
    
    var button: DyteButton = {
        return UIUTility.createButton(text: "close")
    }()
    
    private let automaticClose: Bool
    
    private let automaticCloseTime = 2
    private let onComplete: ()->Void
   
    init(automaticClose: Bool, onCompletion:@escaping()->Void) {
         self.automaticClose = automaticClose
         self.onComplete = onCompletion
         super.init(frame: .zero)
         createSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubviews() {
        let baseStackView = UIUTility.createStackView(axis: .vertical, spacing: tokenSpace.space3)
        let buttonBaseView = UIUTility.wrapped(view: button)
        button.set(.centerX(buttonBaseView),
                   .leading(buttonBaseView, tokenSpace.space2, .greaterThanOrEqual),
                   .sameTopBottom(buttonBaseView))
        if automaticClose {
            baseStackView.addArrangedSubviews(titleLabel)
            Timer.scheduledTimer(withTimeInterval: TimeInterval(automaticCloseTime), repeats: false) { timer in
                self.onComplete()
            }
        }else {
            baseStackView.addArrangedSubviews(titleLabel,buttonBaseView)
        }
        
        self.addSubview(baseStackView)
        baseStackView.set(.centerView(self),
                          .leading(self, tokenSpace.space4, .greaterThanOrEqual),
                          .top(self, tokenSpace.space4, .greaterThanOrEqual))
        self.button.addTarget(self, action: #selector(clickBottom(button:)), for: .touchUpInside)
    }
    
    @objc func clickBottom(button: DyteButton) {
        self.removeFromSuperview()
        self.onComplete()
    }
    
    func show(status: WaitListStatus) {
        self.button.isHidden = true
        if status == WaitListStatus.waiting {
            self.titleLabel.text = "You are in the waiting room, the host will let you in soon."
            self.titleLabel.textColor = tokenColor.textColor.onBackground.shade1000

        }else if status == WaitListStatus.accepted {
            self.removeFromSuperview()
        }else if status == WaitListStatus.rejected {
            self.titleLabel.text = "You were removed from the meeting."
            self.titleLabel.textColor = tokenColor.status.danger
            self.button.isHidden = false

        }
    }
    
    func show(message: String) {
        self.titleLabel.text = message
    }
}
