//
//  DyteMeetingHeaderView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

open class DyteMeetingHeaderView: UIView {

    private let nextPreviousButtonView = NextPreviousButtonView()
    private var nextButtonClick: ((DyteControlBarButton)->Void)?
    private var previousButtonClick: ((DyteControlBarButton)->Void)?
    
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    private let backgroundColorValue = DesignLibrary.shared.color.background.shade900
    let containerView = UIView()

    public lazy var lblSubtitle: DyteParticipantCountView = {
        let label = DyteParticipantCountView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var clockView: DyteClockView = {
        let label = DyteClockView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()
    
   private lazy var recordingView: DyteRecordingView = {
        let view = DyteRecordingView(meeting: self.meeting, title: "Rec", image: nil, appearance: AppTheme.shared.recordingViewAppearance)
        return view
    }()
    
    private let meeting: DyteMobileClient
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setContentTop(offset: CGFloat) {
        self.containerView.get(.top)?.constant = offset
    }
  
    public init(meeting: DyteMobileClient) {
        self.meeting = meeting
        super.init(frame: .zero)
        self.backgroundColor = backgroundColorValue
        createSubViews()
        self.nextPreviousButtonView.isHidden = true
    }

    private func createSubViews() {
        self.addSubview(containerView)
        containerView.set(.sameTopBottom(self, 0, .lessThanOrEqual))
        containerView.set(.sameLeadingTrailing(self, 0, .lessThanOrEqual))
        createSubview(containerView: containerView)
    }
    
    private func createSubview(containerView: UIView) {
        let stackView = DyteUIUTility.createStackView(axis: .vertical, spacing: 4)
        containerView.addSubview(stackView)
       
        let title = DyteMeetingTitleLabel(meeting: self.meeting)
        let stackViewSubTitle = DyteUIUTility.createStackView(axis: .horizontal, spacing: 4)
        stackViewSubTitle.addArrangedSubviews(lblSubtitle,clockView)
        stackView.addArrangedSubviews(title,stackViewSubTitle)
        containerView.addSubview(recordingView)
            
        let nextPreviouStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
        containerView.addSubview(nextPreviouStackView)
      
        stackView.set(.leading(containerView, tokenSpace.space3),
                    .sameTopBottom(containerView, tokenSpace.space2))
        recordingView.set(.centerY(containerView),
                         .top(containerView, tokenSpace.space1, .greaterThanOrEqual),
                         .after(stackView, tokenSpace.space3))
        recordingView.get(.top)?.priority = .defaultLow
        nextPreviouStackView.set(.after(recordingView,tokenSpace.space3, .greaterThanOrEqual),
                          .trailing(containerView,tokenSpace.space3),
                          .centerY(containerView),
                          .top(containerView,tokenSpace.space1,.greaterThanOrEqual))
        nextPreviouStackView.get(.top)?.priority = .defaultLow

        let cameraSwitchButton = DyteSwitchCameraButtonControlBar(meeting: self.meeting)
        cameraSwitchButton.backgroundColor = self.backgroundColor
        nextPreviouStackView.addArrangedSubviews(nextPreviousButtonView, cameraSwitchButton)
       
        self.nextPreviousButtonView.previousButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
        self.nextPreviousButtonView.nextButton.addTarget(self, action: #selector(clickNext(button:)), for: .touchUpInside)
    }
    
    @objc private func clickPrevious(button: DyteControlBarButton) {
        button.showActivityIndicator()
        self.loadPreviousPage()
        self.previousButtonClick?(button)
     }
     
    @objc private func clickNext(button: DyteControlBarButton) {
        button.showActivityIndicator()
        self.loadNextPage()
        self.nextButtonClick?(button)
    }
   
}

extension DyteMeetingHeaderView {
    // MARK: Public methods
    public func refreshNextPreviouButtonState() {
        
        if (meeting.localUser.mediaRoomType == DyteMediaRoomType.hive &&
            meeting.meta.meetingType == DyteMeetingType.webinar) {
            // For Hive Webinar we are not showing any pagination. Hence feature is disabled.
            return
        }

        let nextPagePossible = self.meeting.participants.canGoNextPage
        let prevPagePossible = self.meeting.participants.canGoPreviousPage
       
        if !nextPagePossible && !prevPagePossible {
            //No page view to be shown
            self.nextPreviousButtonView.isHidden = true
        } else {
            self.nextPreviousButtonView.isHidden = false

            self.nextPreviousButtonView.nextButton.isEnabled = nextPagePossible
            self.nextPreviousButtonView.previousButton.isEnabled = prevPagePossible
            self.nextPreviousButtonView.nextButton.hideActivityIndicator()
            self.nextPreviousButtonView.previousButton.hideActivityIndicator()
            self.setNextPreviousText(first: Int(self.meeting.participants.currentPageNumber), second: Int(self.meeting.participants.pageCount) - 1)
        }
    }
    
    public func setClicks(nextButton:@escaping(DyteControlBarButton)->Void, previousButton:@escaping(DyteControlBarButton)->Void) {
        self.nextButtonClick = nextButton
        self.previousButtonClick = previousButton
    }
}

private extension DyteMeetingHeaderView {
   private  func loadPreviousPage() {
        if  self.meeting.participants.canGoPreviousPage == true {
            try?self.meeting.participants.setPage(pageNumber: self.meeting.participants.currentPageNumber - 1)
        }
    }
    
    private  func loadNextPage() {
        if self.meeting.participants.canGoNextPage == true {
            try?self.meeting.participants.setPage(pageNumber: self.meeting.participants.currentPageNumber + 1)
        }
    }
    
    private func setNextPreviousText(first: Int, second: Int) {
        if first == 0 {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = false
            self.nextPreviousButtonView.autolayoutModeEnable = true
        }else {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = true
            self.nextPreviousButtonView.autolayoutModeEnable = false

            self.nextPreviousButtonView.setText(first: "\(first)", second: "\(second)")
        }
    }
}
