//
//  DyteVideoView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 07/02/23.
//

import DyteiOSCore
import UIKit

public class DyteVideoView : UIView {
    
    private var renderView: UIView?// Video View returned from MobileCore SDK
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    private var participant: DyteJoinedMeetingParticipant
    private var onRendered: (()-> Void)?
    private let showSelfPreview: Bool
    private let showScreenShareView: Bool

    public init(participant: DyteJoinedMeetingParticipant, showSelfPreview: Bool = false, showScreenShare: Bool = false) {
        self.participant = participant
        self.showSelfPreview = showSelfPreview
        self.showScreenShareView = showScreenShare
        super.init(frame: .zero)
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteVideoView is being Created")
        }
        set(participant: participant)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(participant: DyteJoinedMeetingParticipant) {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteVideoView set(participant:) is called")
        }
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
        self.participant = participant
        self.participant.addParticipantUpdateListener(participantUpdateListener: self)
        refreshView()
    }
    
    func refreshView() {
        if isDebugModeOn {
            print("Debug DyteUIKit | DyteVideoView refreshView() is called")
        }
        self.showVideoView(participant: self.participant)
    }
    
    public func prepareForReuse() {
        if self.renderView?.superview == self {
            //As Core SDK provides cached renderView, So If someone ask for the view SDK will return the same view and Hence self.renderView.superView is changed , But self.renderView is still pointing to same cached SDK View.
            self.renderView?.removeFromSuperview()
        }
        self.renderView = nil
    }
    
    public func clean() {
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)

        prepareForReuse()
    }
    
    public override func removeFromSuperview() {
        if isDebugModeOn {
            print("Debug DyteUIKit | Removing Video View by calling removeFromSuperview()")
        }
        super.removeFromSuperview()
        prepareForReuse()
    }
    
    deinit {
        print("Debug DyteUIKit | DyteVideoView deinit is calling")
    }
}

extension DyteVideoView {
    
    private func showVideoView(participant: DyteJoinedMeetingParticipant) {
        if  participant.screenShareTrack != nil && self.showScreenShareView == true {
            let view =  participant.getScreenShareVideoView()
            if isDebugModeOn {
                print("Debug DyteUIKit | VideoView Screen share view \(view.bounds) \(view.frame)")
            }
            setRenderView(view:view)
            self.isHidden = false
        } else if let participant = participant as? DyteSelfParticipant, showSelfPreview == true ,participant.videoEnabled == true {
            let selfVideoView = participant.getSelfPreview()
            if isDebugModeOn {
                print("Debug DyteUIKit | Participant \(participant.name) is DyteSelfParticipant videoView bounds \(selfVideoView.bounds) frame \(selfVideoView.frame)")
            }
            setRenderView(view: selfVideoView)
            self.isHidden = false
        } else if let view = participant.getVideoView(), participant.videoEnabled == true {
            if isDebugModeOn {
                print("Debug DyteUIKit | Participant \(participant.name) videoView bounds \(view.bounds) frame \(view.frame)")
            }
            setRenderView(view: view)
            self.isHidden = false
        } else {
            if isDebugModeOn {
                print("Debug DyteUIKit | VideoView participant video is NIL: \(String(describing: participant.getVideoView()))")
            }
            self.isHidden = true
        }
    }
    
    private func setRenderView(view: UIView) {
        self.renderView?.removeFromSuperview()
        self.renderView = view
        self.addSubview(view)
        view.set(.fillSuperView(self))
        if isDebugModeOn {
            print("Debug DyteUIKit | Rendered VideoView \(view) Parent View :\(self) superView: \(String(describing: self.superview))")
        }
        self.onRendered?()
    }
}

extension DyteVideoView: DyteParticipantUpdateListener {
    
    public func onAudioUpdate(isEnabled: Bool) {

    }
    
    public func onPinned() {
        
    }
    
    public func onRemovedAsActiveSpeaker() {
        
    }
    
    public func onScreenShareEnded() {
        
    }
    
    public func onScreenShareStarted() {
        
    }
    
    public func onSetAsActiveSpeaker() {
        
    }
    
    public func onUnpinned() {
        
    }
    
    public func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    public func onVideoUpdate(isEnabled: Bool) {
        if isDebugModeOn {
            print("Debug DyteUIKit | Delegate VideoView onVideoUpdate(participant Name \(participant.name)")
        }
        self.showVideoView(participant: self.participant)
    }
}
