//
//  SetupViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 24/11/22.
//

import UIKit
import DyteiOSCore

public class SetupViewController: UIViewController, KeyboardObservable {
    
    var keyboardObserver: KeyboardObserver?
    let baseView: BaseView = BaseView()
    private var selfPeerView: DyteParticipantTileView!
    let borderRadius = DesignLibrary.shared.borderRadius
    let btnsStackView: BaseStackView = {
        return UIUTility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)
    }()
    
    let btnMic: DyteButton = {
        let button =  DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        return button
    }()
    
    let btnVideo: DyteButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_video_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        return button
    }()
    
    let btnSetting: DyteButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_setting"))), dyteButtonState: .active)
        return button
    }()
    
    let lblJoinAs: DyteText = {return UIUTility.createLabel(text: "Join in as")}()
    
    let textFieldBottom: DyteTextField = {
        let textField = DyteTextField()
        textField.setPlaceHolder(text: "Insert your name")
        return textField
    }()
    
    var btnBottom: DyteJoinButton!
    
    let lblBottom: DyteText = { return UIUTility.createLabel(text: "24 people Present")}()
    
    let spaceToken = DesignLibrary.shared.space
    
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    
    private let baseUrl: String?
    private let completion: ()->Void
    
    private let meetinInfoV2: DyteMeetingInfoV2?
    private let meetinInfo: DyteMeetingInfo?
    private let mobileClient: DyteMobileClient
    private var waitingRoomView: WaitingRoomView?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    
    public init(meetingInfo: DyteMeetingInfo, mobileClient: DyteMobileClient, baseUrl: String? = nil, completion:@escaping()->Void) {
        self.meetinInfo = meetingInfo
        self.mobileClient = mobileClient
        self.baseUrl = baseUrl
        self.completion = completion
        self.meetinInfoV2 = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(meetingInfo: DyteMeetingInfoV2, mobileClient: DyteMobileClient, baseUrl: String? = nil, completion:@escaping()->Void) {
        self.mobileClient = mobileClient
        self.meetinInfoV2 = meetingInfo
        self.meetinInfo = nil
        self.baseUrl = baseUrl
        self.completion = completion
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        self.view.backgroundColor = backgroundColor
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private var viewModel: SetupViewModel!
    
    private func dyteMobileClientInit() {
        
        if let info = self.meetinInfoV2 {
            self.viewModel = SetupViewModel(mobileClient: self.mobileClient, delegate: self, meetingInfoV2: info, meetingInfo: nil)
        }
        
        if let info = self.meetinInfo {
            self.viewModel = SetupViewModel(mobileClient: self.mobileClient, delegate: self, meetingInfoV2: nil, meetingInfo: info)
        }
    }
    
    deinit {
        print("DyteUIKit | SetupViewController deinit is calling")
    }
    
}

//Mark: Public methods
extension SetupViewController {
    public func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
    
    public func setTag(name: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }
}

extension SetupViewController: MeetingDelegate {
    private func setAudioVideoButtonStateAfterMeetingInitialization() {
        btnMic.hideActivityIndicator()
        btnVideo.hideActivityIndicator()
        btnMic.isSelected = !self.mobileClient.localUser.audioEnabled
        btnVideo.isSelected = !self.mobileClient.localUser.videoEnabled
    }
    
    internal func onMeetingInitCompleted() {
        self.setupUIAfterMeetingInit()
        let localUser = self.mobileClient.localUser
        if localUser.permissions.media.canPublishAudio == false {
            btnMic.isHidden = true
        }
        if localUser.permissions.media.canPublishVideo == false {
            btnVideo.isHidden = true
        }
        loadSelfVideoView()
    }
    
    func onMeetingInitFailed() {
        print("DyteUiKit | Error: Meeting Init Failed")
    }
    
}

extension SetupViewController {
    
    func setupView() {
        createSubviews()
        dyteMobileClientInit()
    }
    
    private func setCallBacksForViewModel() {
        self.viewModel.dyteSelfListner.waitListStatusUpdate = { [weak self] status in
            guard let self = self else {return}
            self.showWaitingRoom(status: status)
        }
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { [weak self] keyboardFrame in
            guard let self = self else {return}
            self.view.frame.origin.y = keyboardFrame.origin.y - self.baseView.frame.maxY
        } onHide: { [weak self] in
            guard let self = self else {return}
            self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    private func createSubviews() {
        self.view.addSubview(baseView)
        baseView.set(.sameLeadingTrailing(self.view , spaceToken.space8),
                     .centerY(self.view),
                     .top(self.view, spaceToken.space8, .greaterThanOrEqual))
        setUpActivityIndicator(baseView: baseView)
    }
    
    private func setUpActivityIndicator(baseView: UIView) {
        baseView.addSubview(activityIndicator)
        activityIndicator.set(.centerView(baseView))
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }
    
    private func setupUIAfterMeetingInit() {
        createMeetingSetupUI()
        setupKeyboard()
        setupButtonActions()
        textFieldBottom.addTarget(self, action: #selector(textFieldEditingDidChange), for: .editingChanged)
        textFieldBottom.delegate = self
        self.setTag(name: "")
        setCallBacksForViewModel()
    }
    
    private func createMeetingSetupUI() {
        activityIndicator.stopAnimating()
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: mobileClient, showScreenShareVideo: false, participant: self.mobileClient.localUser))
        
        baseView.addSubview(selfPeerView)
        
        selfPeerView.clipsToBounds = true
        
        selfPeerView.set(.aspectRatio(0.75),
                         .top(baseView),
                         .sameLeadingTrailing(baseView, spaceToken.space6))
        let btnStackView = createBtnView()
        baseView.addSubview(btnStackView)
        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .leading(baseView, 0.0, .greaterThanOrEqual),
                         .centerX(baseView))
        let bottomStackView = createBottomButtonStackView()
        baseView.addSubview(bottomStackView)
        bottomStackView.set(.below(btnStackView, spaceToken.space6),
                            .sameLeadingTrailing(baseView),
                            .bottom(baseView))
        lblBottom.isHidden = true
    }
    
    private func setupButtonActions() {
        btnMic.addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        btnVideo.addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
        btnSetting.addTarget(self, action: #selector(clickSetting(button:)), for: .touchUpInside)
    }
    
    @objc func textFieldEditingDidChange(_ sender: Any) {
        if let text = textFieldBottom.text {
            self.viewModel?.dyteMobileClient.localUser.name = text
            self.setTag(name: text)
        }
    }
    
    
    private  func createBtnView() -> BaseStackView {
        let stackView = UIUTility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)
        
        if let info = self.meetinInfo {
            btnMic.isSelected = !info.enableAudio
            btnVideo.isSelected = !info.enableVideo
        }
        
        if let info = self.meetinInfoV2 {
            btnMic.isSelected = !info.enableAudio
            btnVideo.isSelected = !info.enableVideo
        }
        stackView.addArrangedSubviews(btnMic,btnVideo,btnSetting)
        return stackView
    }
    
    private func createBottomButtonStackView() -> BaseStackView {
        let stackView = UIUTility.createStackView(axis: .vertical, spacing: spaceToken.space2)
        stackView.addArrangedSubviews(lblJoinAs, createBottomJoinButton(), lblBottom)
        return stackView
    }
    
    private func createBottomJoinButton() -> BaseView {
        let view = BaseView()
        view.addSubview(textFieldBottom)
        textFieldBottom.set(.sameLeadingTrailing(view), .top(view))
        btnBottom = addJoinButton(on: view)
        return view
    }
    
    private func addJoinButton(on view: UIView) -> DyteJoinButton {
        let joinButton = DyteJoinButton(meeting: self.mobileClient) { button, success in
            let mobileClient = self.viewModel.dyteMobileClient
            let controller = MeetingViewController(dyteMobileClient: mobileClient, completion: self.completion)
            controller.view.backgroundColor = self.view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
            notificationDelegate?.didReceiveNotification(type: .Joined)
        }
        
        view.addSubview(joinButton)
        joinButton.set(.sameLeadingTrailing(view), .bottom(view), .below(textFieldBottom, spaceToken.space6))
        return joinButton
    }
    
    private func showWaitingRoom(status: WaitListStatus) {
        waitingRoomView?.removeFromSuperview()
        if status != .none {
            let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
            waitingView.backgroundColor = self.view.backgroundColor
            self.view.addSubview(waitingView)
            waitingView.set(.fillSuperView(self.view))
            self.view.endEditing(true)
            waitingRoomView = waitingView
            waitingView.show(status: status)
        }
    }
}

extension SetupViewController : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}


extension SetupViewController {
    
    @objc func clickMic(button: DyteButton) {
        button.showActivityIndicator()
        viewModel?.dyteSelfListner.toggleLocalAudio(completion: { [weak self] isEnabled in
            guard let self = self else {return}
            button.hideActivityIndicator()
            self.selfPeerView.nameTag.refresh()
            button.isSelected = !isEnabled
        })
        
    }
    
    @objc func clickVideo(button: DyteButton) {
        button.showActivityIndicator()
        viewModel?.dyteSelfListner.toggleLocalVideo(completion: { [weak self] isEnabled  in
            guard let self = self else {return}
            button.hideActivityIndicator()
            button.isSelected = !isEnabled
            self.loadSelfVideoView()
        })
    }
    
    @objc func clickSetting(button: DyteButton) {
        if let mobileClient = self.viewModel?.dyteMobileClient {
            mobileClient.localUser.setDisplayName(name: textFieldBottom.text ?? "")
            let controller = SettingViewController(nameTag: textFieldBottom.text ?? "", dyteMobileClient: mobileClient)
            controller.view.backgroundColor = self.view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
        }
    }
}
