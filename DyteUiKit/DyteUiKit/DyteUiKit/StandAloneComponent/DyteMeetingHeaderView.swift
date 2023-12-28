//
//  DyteMeetingHeaderView.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import DyteiOSCore

open class DyteMeetingHeaderView: UIView {
    
    public  let nextPreviousButtonView = NextPreviousButtonView()
    private var nextButtonClick: ((DyteControlBarButton)->Void)?
    private var previousButtonClick: ((DyteControlBarButton)->Void)?
    
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    let backgroundColorValue = DesignLibrary.shared.color.background.shade900
   
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
    
   lazy var recordingView: DyteRecordingView = {
       let view = DyteRecordingView(meeting: self.meeting, title: "Rec", image: nil, appearance: AppTheme.shared.recordingViewAppearance)
        view.isHidden = true
        return view
    }()
    
   
    private let meeting: DyteMobileClient
    
    init(meeting: DyteMobileClient) {
        self.meeting = meeting
        super.init(frame: .zero)
        self.backgroundColor = backgroundColorValue
        createSubViews()
        self.nextPreviousButtonView.isHidden = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func createSubViews() {
        let stackView = UIUTility.createStackView(axis: .vertical, spacing: 4)
        self.addSubview(stackView)
        let title = DyteMeetingTitle(meeting: self.meeting)
        let stackViewSubTitle = UIUTility.createStackView(axis: .horizontal, spacing: 4)
        stackViewSubTitle.addArrangedSubviews(lblSubtitle,clockView)
        stackView.addArrangedSubviews(title,stackViewSubTitle)
        self.addSubview(recordingView)
            
       let nextPreviouStackView = UIUTility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
       self.addSubview(nextPreviouStackView)
      
       stackView.set(.leading(self, tokenSpace.space3),
                    .sameTopBottom(self, tokenSpace.space2))
       recordingView.set(.centerY(self),
                         .top(self, tokenSpace.space1, .greaterThanOrEqual),
                         .after(stackView, tokenSpace.space3))

       nextPreviouStackView.set(.after(recordingView,tokenSpace.space3, .greaterThanOrEqual),
                          .trailing(self,tokenSpace.space3),
                          .centerY(self),
                          .top(self,tokenSpace.space1,.greaterThanOrEqual))
 
        let cameraSwitchButton = DyteSwitchCameraButtonControlBar(mobileClient: self.meeting)
        cameraSwitchButton.backgroundColor = self.backgroundColor
        nextPreviouStackView.addArrangedSubviews(nextPreviousButtonView, cameraSwitchButton)
       
        self.nextPreviousButtonView.previousButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
        self.nextPreviousButtonView.nextButton.addTarget(self, action: #selector(clickNext(button:)), for: .touchUpInside)
    }
    

    public func setNextPreviousText(first: Int, second: Int) {
        if first == 0 {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = false
            self.nextPreviousButtonView.autolayoutModeEnable = true
        }else {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = true
            self.nextPreviousButtonView.autolayoutModeEnable = false

            self.nextPreviousButtonView.setText(first: "\(first)", second: "\(second)")
        }
    }
    
    public  func setClicks(nextButton:@escaping(DyteControlBarButton)->Void, previousButton:@escaping(DyteControlBarButton)->Void) {
        self.nextButtonClick = nextButton
        self.previousButtonClick = previousButton
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
    
}
