//
//  DyteRecordingView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

public protocol DyteRecordingViewAppearance: BaseAppearance {
    var textColor: StatusColor.Shade {get set}
    var font: UIFont {get set}
    var imageBackGroundColor: StatusColor.Shade {get set}
}

public class DyteRecordingViewAppearanceModel: DyteRecordingViewAppearance {
    public var textColor: StatusColor.Shade
    
    public var font: UIFont
    
    public var imageBackGroundColor: StatusColor.Shade
    
    public var desingLibrary: DyteDesignTokens
    
    public required init(designLibrary: DyteDesignTokens) {
        self.desingLibrary = designLibrary
        self.font =  UIFont.boldSystemFont(ofSize: 12)
        self.textColor =  designLibrary.color.status.danger
        self.imageBackGroundColor = designLibrary.color.status.danger
    }
}

public class DyteRecordingView: UIView {
    private let tokenSpace = DesignLibrary.shared.space

    private var title: String
    private var image: DyteImage?
    private let appearance: DyteRecordingViewAppearance
    private let meeting: DyteMobileClient
    
    public init(meeting: DyteMobileClient, title: String = "Rec", image: DyteImage? = nil, appearance: DyteRecordingViewAppearance = DyteRecordingViewAppearanceModel(designLibrary: DesignLibrary.shared)) {
        self.title = title
        self.image = image
        self.appearance = appearance
        self.meeting = meeting
        super.init(frame: .zero)
        createSubViews()
        meeting.addRecordingEventsListener(recordingEventsListener: self)
        if meeting.recording.recordingState == .recording || meeting.recording.recordingState == .starting {
           self.blinking(start: true)
        }else if meeting.recording.recordingState == .stopping || meeting.recording.recordingState == .idle {
            self.blinking(start: false)
        }
        self.accessibilityIdentifier = "Recording_Red_Dot"
    }
    
    deinit {
        self.meeting.removeRecordingEventsListener(recordingEventsListener: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubViews() {
        let stackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: 4)
        var imageView = BaseImageView()
        if let image = self.image {
            imageView = DyteUIUTility.createImageView(image: image)
        }
        let title = DyteUIUTility.createLabel(text: self.title)
        title.font = appearance.font
        title.textColor = appearance.textColor
        stackView.addArrangedSubviews(imageView,title)
        if self.image == nil {
            imageView.set(.width(tokenSpace.space2),
                          .height(tokenSpace.space2))
            imageView.layer.cornerRadius = tokenSpace.space1
        }
        imageView.backgroundColor = appearance.imageBackGroundColor
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
    }
    
    public func blinking(start: Bool) {
        self.isHidden = !start
        if start {
            // I have to use DispatchQueue here because recording view didn't blink, and by doing so its start working
            DispatchQueue.main.async {
                self.blink()
            }
        }else {
            self.stopBlink()
        }
    }
}

extension  DyteRecordingView: DyteRecordingEventsListener {
    public func onMeetingRecordingPauseError(e: KotlinException) {
        
    }
    
    public func onMeetingRecordingResumeError(e: KotlinException) {
        
    }
    
    public  func onMeetingRecordingEnded() {
        self.blinking(start: false)
        NotificationCenter.default.post(name: Notification.Name("Notify_RecordingUpdate"), object: nil, userInfo: nil)
    }
    
    public  func onMeetingRecordingStarted() {
        self.blinking(start: true)
        NotificationCenter.default.post(name: Notification.Name("Notify_RecordingUpdate"), object: nil, userInfo: nil)
    }
    
    public  func onMeetingRecordingStateUpdated(state: DyteRecordingState) {
        
    }
    
    public   func onMeetingRecordingStopError(e: KotlinException) {
        
    }
    
}
