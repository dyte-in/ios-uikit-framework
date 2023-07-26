//
//  DytePluginView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 06/01/23.
//

import UIKit
import DyteiOSCore
import WebKit

public class ActiveListView: UIView {
    
    private let scrollView : UIScrollView = {return UIScrollView()}()
    private var buttons = [ScreenShareTabButton]()
    let tokenSpace = DesignLibrary.shared.space
    let tokenColor = DesignLibrary.shared.color
    private var stackView: UIStackView!
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = tokenColor.background.shade900
        self.addSubview(scrollView)
        scrollView.set(.fillSuperView(self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setButtons(buttons: [ScreenShareTabButton]) {
        if stackView == nil {
            stackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
            scrollView.addSubview(stackView)
            stackView.set(.trailing(scrollView, tokenSpace.space3),
                          .leading(scrollView, tokenSpace.space3),
                          .sameTopBottom(self, tokenSpace.space2))
        }
        for button in self.buttons {

            button.removeFromSuperview()
        }
        
        for button in buttons {
            stackView.addArrangedSubview(button)
        }
        self.buttons = buttons
    }
    
}

class ActiveSpeakerPinView: UIView {
    let spaceToken = DesignLibrary.shared.space

    private lazy var pinView : UIView = {
        let baseView = UIView()
        let imageView = UIUTility.createImageView(image: DyteImage(image:ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.fillSuperView(baseView, spaceToken.space1))
        return baseView
    }()
    private(set) var videoView: DyteVideoView!
   
    func pinView(show: Bool) {
        let heightWidth:CGFloat = 30
        if pinView.superview == nil {
            self.addSubview(pinView)
            pinView.backgroundColor = tokenColor.background.shade900
            pinView.set(.leading(self, tokenSpace.space3),
                        .top(self, tokenSpace.space3),
                        .height(heightWidth),
                        .width(heightWidth))
            pinView.layer.cornerRadius = spaceToken.space1
        }
        pinView.isHidden = !show
    }
    private let participant: DyteJoinedMeetingParticipant
    
    init(participant:DyteJoinedMeetingParticipant) {
        self.participant = participant
        super.init(frame: .zero)
        createSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func createSubview() {
       let videoView = DyteVideoView(participant: self.participant)
        self.addSubview(videoView)
        videoView.set(.fillSuperView(self))
        self.videoView = videoView
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handler)))

    }
    
    @objc func handler(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.superview)
        let animationDuration = 0.5
        let draggedView = gesture.view
        draggedView?.center = location
        
        if gesture.state == .ended {
            if self.frame.midX >= self.superview!.layer.frame.width / 2 {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.x = self.superview!.layer.frame.width - (self.frame.width/2)
                }, completion: nil)
            }else{
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.x = self.frame.width/2
                }, completion: nil)
            }
            if self.frame.minY <= 0 {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.y = self.frame.height/2
                }, completion: nil)
            }else if self.frame.maxY >= self.superview!.layer.frame.height {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.y = self.superview!.layer.frame.height - (self.frame.height/2)
                }, completion: nil)
            }
        }
    }
}

public class PluginView: UIView {
    
    public  let activeListView = ActiveListView()
    public  let pluginVideoView: DyteParticipantTileView
    private var clickAction:((ScreenShareTabButton)-> Void)?
    private let stackView = UIUTility.createStackView(axis: .vertical, spacing: 0)
    private let activeSpeakerView: ActiveSpeakerPinView
    let backgroundColorValue = DesignLibrary.shared.color.background.video
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    let spaceToken = DesignLibrary.shared.space
    
    init(videoPeerViewModel: VideoPeerViewModel) {
        pluginVideoView = DyteParticipantTileView(viewModel: videoPeerViewModel)
        pluginVideoView.nameTag.isHidden = true
        activeSpeakerView = ActiveSpeakerPinView(participant: videoPeerViewModel.participant)
        super.init(frame: .zero)
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
        let pluginBaseView = UIView()
        stackView.addArrangedSubviews(activeListView,pluginBaseView)
        pluginBaseView.addSubview(pluginVideoView)
        pluginVideoView.set(.fillSuperView(pluginBaseView))

        self.addSubview(activeSpeakerView)
        activeSpeakerView.layer.masksToBounds = true
        activeSpeakerView.backgroundColor = backgroundColorValue
        activeSpeakerView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        activeSpeakerView.set(.trailing(self, spaceToken.space2),
                              .bottom(self, spaceToken.space2),
                              .equateAttribute(.width, toView: self, toAttribute: .width, withRelation: .equal, multiplier: 0.4),
                              .equateAttribute(.height, toView: self, toAttribute: .height, withRelation: .equal, multiplier: 0.4))
        
        activeSpeakerView.isHidden = true

    }
    
    public func setButtons(buttons: [ScreenShareTabButton],  selectedIndex: Int?, clickAction:@escaping(ScreenShareTabButton)->Void)  {
        if let index = selectedIndex , index < buttons.count {
            buttons[index].isSelected = true
        }
        for (index, button) in buttons.enumerated() {
            button.index = index
            button.addTarget(self, action: #selector(clickButton(button:)), for: .touchUpInside)
        }
        self.clickAction = clickAction
        activeListView.setButtons(buttons: buttons)
    }
    
    public func showAndHideActiveButtonListView(buttons: [ScreenShareTabButton]) {
        activeListView.isHidden = buttons.count > 1 ? false : true
    }
    
   @objc func clickButton(button: ScreenShareTabButton) {
       self.clickAction?(button)
    }
    
    private var webView: UIView?
    
    func show(pluginView view: UIView) {
        if let constraints = webView?.constraints {
            webView?.removeConstraints(constraints)
        }
        webView?.removeFromSuperview()
        pluginVideoView.addSubview(view)
        view.set(.fillSuperView(pluginVideoView))
        webView = view
        webView?.isHidden = false
    }
    
    public func showVideoView(participant: DyteJoinedMeetingParticipant) {
        webView?.isHidden = true
        self.pluginVideoView.viewModel.set(participant: participant)
    }
    
    func showPinnedView(participant: DyteJoinedMeetingParticipant) {
        activeSpeakerView.pinView(show: true)
        showActiveSpeakerOrPinnedView(participant: participant)
    }
    
    func showActiveSpeakerView(participant: DyteJoinedMeetingParticipant) {
        activeSpeakerView.pinView(show: false)
        showActiveSpeakerOrPinnedView(participant: participant)
    }
    private func showActiveSpeakerOrPinnedView(participant: DyteJoinedMeetingParticipant) {
        let _ = activeSpeakerView.videoView.set(participant: participant)
        activeSpeakerView.isHidden = false
    }
    
    func hideActiveSpeaker() {
        if activeSpeakerView.isHidden {
            return
        }
        activeSpeakerView.videoView.prepareForReuse()
        activeSpeakerView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

