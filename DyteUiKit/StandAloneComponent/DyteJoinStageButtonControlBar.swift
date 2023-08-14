//
//  DyteVideoButton.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 10/04/23.
//

import DyteiOSCore

class  DyteJoinStageButtonControlBar: DyteControlBarButton {
//    private let mobileClient: DyteMobileClient
//    private var isJoined: Bool = false
//    init(mobileClient: DyteMobileClient) {
//        self.mobileClient = mobileClient
//        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Join stage")
//        self.setSelected(image: DyteImage(image: ImageProvider.image(named: "icon_stage_leave")), title: "Leave stage")
//        self.selectedStateTintColor = tokenColor.status.danger
//        self.addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
//        self.isSelected = mobileClient.webinar.isPresenting()
//
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func showStage(isJoined: Bool) {
//        self.isJoined = isJoined
//        self.isSelected = isJoined
//    }
//
//    @objc func click(button: DyteControlBarButton) {
//        if self.isJoined {
//            button.showActivityIndicator(title: "Leaving...")
//            self.mobileClient.webinar.leaveStage()
////            self.mobileClient.webinar.leaveStage { [weak self] in
////                guard let self = self else {return}
////                button.hideActivityIndicator()
////                self.showStage(isJoined: self.mobileClient.webinar.isPresenting())
////            } onFailure: { [weak self] message in
////                guard let self = self else {return}
////                button.hideActivityIndicator()
////                self.showStage(isJoined: self.mobileClient.webinar.isPresenting())
////            }
//
//        }else {
//            button.showActivityIndicator(title: "Joining...")
////            self.mobileClient.webinar.joinStage {[weak self] in
////                guard let self = self else {return}
////                button.hideActivityIndicator()
////                self.showStage(isJoined: self.mobileClient.webinar.isPresenting())
////            } onFailure: {[weak self] message in
////                guard let self = self else {return}
////                button.hideActivityIndicator()
////                self.showStage(isJoined: self.mobileClient.webinar.isPresenting())
////            }
//
//        }
//
//        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
//            button.hideActivityIndicator()
//            self.showStage(isJoined: !self.isJoined)
//        }
//    }
}


