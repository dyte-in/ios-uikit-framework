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

class DyteRecordingView: UIView {
    private let tokenSpace = DesignLibrary.shared.space

    private var title: String
    private var image: DyteImage?
    private let appearance: DyteRecordingViewAppearance
    private let meeting: DyteMobileClient
    
    init(meeting: DyteMobileClient,title: String, image: DyteImage? = nil, appearance: DyteRecordingViewAppearance = DyteRecordingViewAppearanceModel(designLibrary: DesignLibrary.shared)) {
        self.title = title
        self.image = image
        self.appearance = appearance
        self.meeting = meeting
        super.init(frame: .zero)
        createSubViews()
        meeting.addRecordingEventsListener(recordingEventsListener: self)
        self.accessibilityIdentifier = "Recording_Red_Dot"
    }
    
    deinit {
        self.meeting.removeRecordingEventsListener(recordingEventsListener: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubViews() {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: 4)
        var imageView = BaseImageView()
        if let image = self.image {
            imageView = UIUTility.createImageView(image: image)
        }
        let title = UIUTility.createLabel(text: self.title)
        title.font = appearance.font
        title.textColor = appearance.textColor
        stackView.addArrangedSubviews(imageView,title)
        if self.image == nil {
            imageView.set(.width(tokenSpace.space2),
                          .height(tokenSpace.space2))
            imageView.backgroundColor = appearance.imageBackGroundColor
            imageView.layer.cornerRadius = tokenSpace.space1
        }
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
    }
    
    func meetingRecording(start: Bool) {
        self.isHidden = !start
        if start {
            self.blink()
        }else {
            self.stopBlink()
        }
    }
}

extension  DyteRecordingView: DyteRecordingEventsListener {
    func onMeetingRecordingPauseError(e: KotlinException) {
        
    }
    
    func onMeetingRecordingResumeError(e: KotlinException) {
        
    }
    
    public  func onMeetingRecordingEnded() {
        self.meetingRecording(start: false)
    }
    
    public  func onMeetingRecordingStarted() {
        self.meetingRecording(start: true)
    }
    
    public  func onMeetingRecordingStateUpdated(state: DyteRecordingState) {
        
    }
    
    public   func onMeetingRecordingStopError(e: KotlinException) {
        
    }
    
}
