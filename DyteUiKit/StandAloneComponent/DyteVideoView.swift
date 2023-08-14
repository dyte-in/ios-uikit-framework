//
//  DyteVideoView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 07/02/23.
//

import DyteiOSCore
import UIKit

public class DyteVideoView : UIView {
    
    private var renderView: UIView?
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    private var participant: DyteJoinedMeetingParticipant
    private var onRendered: (()-> Void)?
    private let showSelfPreview: Bool
    init(participant: DyteJoinedMeetingParticipant, showSelfPreview: Bool = false) {
        self.participant = participant
        self.showSelfPreview = showSelfPreview
        super.init(frame: .zero)
        set(participant: participant)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(participant: DyteJoinedMeetingParticipant) {
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
        self.participant = participant
        self.participant.addParticipantUpdateListener(participantUpdateListener: self)
        refreshView()
    }
    
    func refreshView() {
        self.showVideoView(participant: self.participant)
    }
    
    public func prepareForReuse() {
        if self.renderView?.superview == self {
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
            print("Debug DyteUIKit | Removing Video View")
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
        if let screenShareParticipant = participant as? DyteScreenShareMeetingParticipant {
            if  screenShareParticipant.screenShareTrack != nil {
                let view =  screenShareParticipant.getScreenShareVideoView()
                if isDebugModeOn {
                    print("Debug DyteUIKit | VideoView Screen share view \(view.bounds) \(view.frame)")
                }
                setRenderView(view:view)
                self.isHidden = false
            }else {
                self.isHidden = true
            }
        }else {
            if let participant = participant as? DyteSelfParticipant, showSelfPreview == true ,participant.videoEnabled == true {
                setRenderView(view: participant.getSelfPreview())
                self.isHidden = false
                
            } else if let view = participant.getVideoView(), participant.videoEnabled == true {
                if isDebugModeOn {
                    print("Debug DyteUIKit | VideoView participant video \(view.bounds) \(view.frame)")
                }
                setRenderView(view: view)
                self.isHidden = false

            } else {
                if isDebugModeOn {
                    print("Debug DyteUIKit | VideoView participant video is Nil")
                }
                self.isHidden = true
            }
        }
    }
    
    private func setRenderView(view: UIView) {
        if isDebugModeOn {
            print("\n Debug DyteUIKit | will render view \(view) Parent View\(self.bounds) Name \(participant.name)")
        }
        
        self.renderView?.removeFromSuperview()
        self.renderView = view
        let rctMlView = view.subviews[0]
        rctMlView.set(.fillSuperView(view))
        self.addSubview(view)
        view.set(.fillSuperView(self))
        if isDebugModeOn {
            print("Debug DyteUIKit | DID render view \(view) Parent View\(self.bounds)")
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
