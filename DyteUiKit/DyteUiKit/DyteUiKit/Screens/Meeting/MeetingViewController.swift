//
//  MeetingViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 21/12/22.
//

import DyteiOSCore
import UIKit
import AVFAudio

public struct Animations {
    public static let gridViewAnimationDuration = 0.3
}

public protocol MeetingViewControllerDataSource {
    func getTopbar(viewController: MeetingViewController) -> DyteMeetingHeaderView?
    func getMiddleView(viewController: MeetingViewController) -> UIView?
    func getBottomTabbar(viewController: MeetingViewController) -> DyteMeetingControlBar?
}

public class MeetingViewController: DyteBaseViewController {
    
    private var gridView: GridView<DyteParticipantTileContainerView>!
    let pluginView: DytePluginView
    let pinnedView = DyteParticipantTileContainerView()

    let gridBaseView = UIView()
    private let pluginPinnedBaseView = UIView()
    private var fullScreenView: FullScreenView!
    
    let baseContentView = UIView()
    
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    public var dataSource: MeetingViewControllerDataSource?

    let fullScreenButton: DyteControlBarButton = {
        let button = DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_show_fullscreen")))
        button.setSelected(image:  DyteImage(image: ImageProvider.image(named: "icon_hide_fullscreen")))
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
    let viewModel: MeetingViewModel
    
    private var topBar: DyteMeetingHeaderView!
    private var bottomBar: DyteControlBar!
    
    internal let onFinishedMeeting: ()->Void
    private var viewWillAppear = false
    
    internal var moreButtonBottomBar: DyteControlBarButton?
    private var layoutContraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutPortraitContraintPluginBaseVariableHeight: NSLayoutConstraint!
    private var layoutLandscapeContraintPluginBaseVariableWidth: NSLayoutConstraint!
    private var layoutContraintPluginBaseZeroWidth: NSLayoutConstraint!
    
    private var waitingRoomView: WaitingRoomView?

   public init(meeting: DyteMobileClient, completion:@escaping()->Void) {
        //TODO: Check the local user passed now
        self.pluginView = DytePluginView(videoPeerViewModel:VideoPeerViewModel(mobileClient: meeting, participant: meeting.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        self.onFinishedMeeting = completion
        self.viewModel = MeetingViewModel(dyteMobileClient: meeting)
        super.init(dyteMobileClient: meeting)
        notificationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.topBar.containerView.get(.top)?.constant = self.view.safeAreaInsets.top
        if UIScreen.isLandscape() {
            self.bottomBar.setWidth()
        }else {
            self.bottomBar.setHeight()
        }
        setLeftPaddingContraintForBaseContentView()
    }
    
    private func setLeftPaddingContraintForBaseContentView() {
        if UIScreen.deviceOrientation == .landscapeLeft {
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.bottom
        }else if UIScreen.deviceOrientation == .landscapeRight {
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.right
        }
    }
    
    private func shouldShowNotificationBubble() -> Bool {
        return (self.meeting.getPendingParticipantCount() > 0 || Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: self.meeting.chat.messages.count, totalsPolls: self.meeting.polls.polls.count) > 0)
    }
    
    public func updateMoreButtonNotificationBubble() {
        if shouldShowNotificationBubble() {
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
        }else {
            self.moreButtonBottomBar?.notificationBadge.isHidden = true
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.accessibilityIdentifier = "Meeting_Base_View"
        self.view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        createTopbar()
        createBottomBar()
        createSubView()
        applyConstraintAsPerOrientation()
        setInitialsConfiguration()
        setupNotifications()
        self.viewModel.delegate = self
                
        self.viewModel.dyteSelfListner.observeSelfRemoved { [weak self] success in
            guard let self = self else {return}
            
            func showWaitingRoom(status: WaitListStatus, time:TimeInterval, onComplete:@escaping()->Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            //self.dismiss(animated: true)
            showWaitingRoom(status: .rejected, time: 2) { [weak self] in
                guard let self = self else {return}
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }
        self.viewModel.dyteSelfListner.observePluginScreenShareTabSync(update: { id in
            self.selectPluginOrScreenShare(id: id)
        })
       
        if self.meeting.localUser.permissions.waitingRoom.canAcceptRequests {
            self.viewModel.waitlistEventListner.participantJoinedCompletion = {[weak self] participant in
                guard let self = self else {return}
                
                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
                
            }
            
            self.viewModel.waitlistEventListner.participantRequestRejectCompletion = {[weak self] participant in
                guard let self = self else {return}
                updateMoreButtonNotificationBubble()
            }
            self.viewModel.waitlistEventListner.participantRequestAcceptedCompletion = {[weak self] participant in
                guard let self = self else {return}
                updateMoreButtonNotificationBubble()
            }
            self.viewModel.waitlistEventListner.participantRemovedCompletion = {[weak self] participant in
                guard let _ = self else {return}

                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
        }
        addWaitingRoom { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        setUpReconnection { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        } success: {  [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGrid()
            self.refreshPluginsView()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            self.viewModel.refreshActiveParticipants()
            self.viewModel.trackOnGoingState()
            
            if shouldShowNotificationBubble() {
                self.moreButtonBottomBar?.notificationBadge.isHidden = false
            } else {
                self.moreButtonBottomBar?.notificationBadge.isHidden = false
            }
        }
    }
    
    public func refreshMeetingGrid(forRotation: Bool = false) {
        if isDebugModeOn {
            print("Debug DyteUIKit | refreshMeetingGrid")
        }
        
        self.meetingGridPageBecomeVisible()
        
        let arrModels = self.viewModel.arrGridParticipants
        
        if isDebugModeOn {
            print("Debug DyteUIKIt | refreshing Finished")
        }
        
        func prepareGridViewsForReuse() {
            self.gridView.prepareForReuse { peerView in
                peerView.prepareForReuse()
            }
        }
        
        
        func loadGridAndPluginView(showPluginPinnedView: Bool, animation: Bool) {
            self.showHidePluginPinnedAndScreenShareView()
            self.loadGrid(fullScreen: !showPluginPinnedView, animation: !animation, completion: {
                if forRotation == false {
                    prepareGridViewsForReuse()
                    populateGridChildViews(models: arrModels)
                }
            })
        }
        
        if self.viewModel.pinOrPluginModeIsActive() {
            loadGridAndPluginView(showPluginPinnedView: true, animation: false)
        } else {
            loadGridAndPluginView(showPluginPinnedView: false, animation: false)
        }
        
        if self.viewModel.pinOrPluginModeIsActive() {
            self.refreshPluginsView()
        }
        
        func populateGridChildViews(models: [GridCellViewModel]) {
            for i in 0..<models.count {
                if let peerContainerView = self.gridView.childView(index: i) {
                    peerContainerView.setParticipant(meeting: self.meeting, participant: models[i].participant)
                }
            }
            if isDebugModeOn {
                print("Debug DyteUIKit | Iterating for Items \(arrModels.count)")
                for i in 0..<models.count {
                    if let peerContainerView = self.gridView.childView(index: i), let tileView = peerContainerView.tileView {
                        print("Debug DyteUIKit | Tile View Exists \(tileView) \nSuperView \(String(describing: tileView.superview))")
                    }
                }
            }
        }
    }
    
    internal func getBottomBar() -> DyteControlBar {
        let controlBar =  DyteMeetingControlBar(meeting: self.meeting, delegate: nil, presentingViewController: self) {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        return controlBar
    }

    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.removeObserver(self, name: Notification.Name("NotificationAllChatsRead"), object: nil)
        if isDebugModeOn {
            print("DyteUIKit | MeetingViewController Deinit is calling ")
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.presentedViewController?.dismiss(animated: false)
        bottomBar.moreButton.hideBottomSheet()
        if UIScreen.isLandscape() {
            bottomBar.moreButton.superview?.isHidden = true
        }else {
            bottomBar.moreButton.superview?.isHidden = false
        }
       
        self.applyConstraintAsPerOrientation { [weak self] in
            guard let self = self else {return}
            self.fullScreenButton.isHidden = true
            self.closefullscreen()
        } onLandscape: { [weak self] in
            guard let self = self else {return}
            self.fullScreenButton.isSelected = false
            self.fullScreenButton.isHidden = false
        }
        
        self.showPinnedPluginViewAsPerOrientation(show: false)
        self.setLeftPaddingContraintForBaseContentView()
        DispatchQueue.main.async {
            self.refreshMeetingGrid(forRotation: true)
        }
    }

}

// Bottom bar related Methods
extension MeetingViewController {
private func createBottomBar() {
    self.bottomBar = self.dataSource?.getBottomTabbar(viewController: self) ?? getBottomBar()
    self.moreButtonBottomBar = self.bottomBar.moreButton
    self.view.addSubview(self.bottomBar)
    addBottomBarConstraint()
}
    

    private  func addBottomBarConstraint() {
        addPortraitContraintBottombar()
        addLandscapeContraintBottombar()
        if UIScreen.isLandscape() {
            self.moreButtonBottomBar?.superview?.isHidden = true
        }
    }
    
    private func addPortraitContraintBottombar() {
        self.bottomBar.set(.sameLeadingTrailing(self.view),
                        .bottom(self.view))
        portraitConstraints.append(contentsOf: [self.bottomBar.get(.leading)!,
                                                self.bottomBar.get(.trailing)!,
                                                self.bottomBar.get(.bottom)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeContraintBottombar() {
        self.bottomBar.set(.trailing(self.view),
                        .sameTopBottom(self.view))
        landscapeConstraints.append(contentsOf: [self.bottomBar.get(.trailing)!,
                                                self.bottomBar.get(.top)!,
                                                self.bottomBar.get(.bottom)!])
        setLandscapeContraintAsDeactive()
    }
    

}

private extension MeetingViewController {
    
    private func setInitialsConfiguration() {
        // self.topBar.setInitialConfiguration()
    }
    
    private func createSubView() {
        self.view.addSubview(baseContentView)
        baseContentView.addSubview(pluginPinnedBaseView)
        baseContentView.addSubview(gridBaseView)
        pluginPinnedBaseView.accessibilityIdentifier = "Grid_Plugin_View"
        
        gridView = GridView(showingCurrently: 9, getChildView: {
            return DyteParticipantTileContainerView()
        })
        
        gridBaseView.addSubview(gridView)
        pluginPinnedBaseView.addSubview(pluginView)
        pluginPinnedBaseView.addSubview(pinnedView)
        
        pluginView.addSubview(fullScreenButton)
        
        fullScreenButton.set(.trailing(pluginView, dyteSharedTokenSpace.space1),
                             .bottom(pluginView,dyteSharedTokenSpace.space1))
        
        fullScreenButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        self.fullScreenButton.isHidden = !UIScreen.isLandscape()
        fullScreenButton.isSelected = false
        addPortraitConstraintForSubviews()
        addLandscapeConstraintForSubviews()
        showPinnedPluginViewAsPerOrientation(show: false)
    }
    
    @objc func buttonClick(button: DyteButton) {
        if UIScreen.isLandscape() {
            if button.isSelected == false {
                pluginView.removeFromSuperview()
                self.addFullScreenView(contentView: pluginView)
            }else {
                closefullscreen()
            }
            button.isSelected = !button.isSelected
        }
    }
    
    private func closefullscreen() {
        if fullScreenView?.isVisible == true {
            self.pluginPinnedBaseView.addSubview(self.pluginView)
            self.pluginView.set(.fillSuperView(self.pluginPinnedBaseView))
            self.removeFullScreenView()
        }
    }
    
    private func showPinnedPluginViewAsPerOrientation(show: Bool) {
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        layoutContraintPluginBaseZeroHeight.isActive = false
        layoutLandscapeContraintPluginBaseVariableWidth.isActive = false
        layoutContraintPluginBaseZeroWidth.isActive = false
        
        if UIScreen.isLandscape() {
            layoutLandscapeContraintPluginBaseVariableWidth.isActive = show
            layoutContraintPluginBaseZeroWidth.isActive = !show
        }else {
            layoutPortraitContraintPluginBaseVariableHeight.isActive = show
            layoutContraintPluginBaseZeroHeight.isActive = !show
        }
    }
    
    private func addPortraitConstraintForSubviews() {
        
        baseContentView.set(.sameLeadingTrailing(self.view),
                            .below(topBar),
                            .above(bottomBar))
        portraitConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                baseContentView.get(.trailing)!,
                                                baseContentView.get(.top)!,
                                                baseContentView.get(.bottom)!])
        
        pluginPinnedBaseView.set(.sameLeadingTrailing(baseContentView),
                                 .top(baseContentView))
        portraitConstraints.append(contentsOf: [pluginPinnedBaseView.get(.leading)!,
                                                pluginPinnedBaseView.get(.trailing)!,
                                                pluginPinnedBaseView.get(.top)!])
        
        layoutPortraitContraintPluginBaseVariableHeight = NSLayoutConstraint(item: pluginPinnedBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.7, constant: 0)
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        
        layoutContraintPluginBaseZeroHeight = NSLayoutConstraint(item: pluginPinnedBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)
        
        layoutContraintPluginBaseZeroHeight.isActive = false
        
        
        gridBaseView.set(.sameLeadingTrailing(baseContentView),
                         .below(pluginPinnedBaseView),
                         .bottom(baseContentView))
        
        portraitConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                gridBaseView.get(.trailing)!,
                                                gridBaseView.get(.top)!,
                                                gridBaseView.get(.bottom)!])
        
        gridView.set(.fillSuperView(gridBaseView))
        portraitConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                gridView.get(.trailing)!,
                                                gridView.get(.top)!,
                                                gridView.get(.bottom)!])
        pluginView.set(.fillSuperView(pluginPinnedBaseView))
        portraitConstraints.append(contentsOf: [pluginView.get(.leading)!,
                                                pluginView.get(.trailing)!,
                                                pluginView.get(.top)!,
                                                pluginView.get(.bottom)!])
        
        pinnedView.set(.fillSuperView(pluginPinnedBaseView))
        portraitConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                pinnedView.get(.trailing)!,
                                                pinnedView.get(.top)!,
                                                pinnedView.get(.bottom)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeConstraintForSubviews() {
        
        baseContentView.set(.leading(self.view),
                            .below(self.topBar),
                            .bottom(self.view),
                            .before(bottomBar))
        
        landscapeConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                 baseContentView.get(.trailing)!,
                                                 baseContentView.get(.top)!,
                                                 baseContentView.get(.bottom)!])
        
        
        pluginPinnedBaseView.set(.leading(baseContentView),
                                 .sameTopBottom(baseContentView))
        landscapeConstraints.append(contentsOf: [pluginPinnedBaseView.get(.leading)!,
                                                 pluginPinnedBaseView.get(.bottom)!,
                                                 pluginPinnedBaseView.get(.top)!])
        
        layoutLandscapeContraintPluginBaseVariableWidth = NSLayoutConstraint(item: pluginPinnedBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.75, constant: 0)
        layoutLandscapeContraintPluginBaseVariableWidth.isActive = false
        
        layoutContraintPluginBaseZeroWidth = NSLayoutConstraint(item: pluginPinnedBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)
        
        layoutContraintPluginBaseZeroWidth.isActive = false
        
        
        gridBaseView.set(.sameTopBottom(baseContentView),
                         .after(pluginPinnedBaseView),
                         .trailing(baseContentView))
        
        landscapeConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                 gridBaseView.get(.trailing)!,
                                                 gridBaseView.get(.top)!,
                                                 gridBaseView.get(.bottom)!])
        
        gridView.set(.fillSuperView(gridBaseView))
        landscapeConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                 gridView.get(.trailing)!,
                                                 gridView.get(.top)!,
                                                 gridView.get(.bottom)!])
        pluginView.set(.fillSuperView(pluginPinnedBaseView))
        landscapeConstraints.append(contentsOf: [pluginView.get(.leading)!,
                                                 pluginView.get(.trailing)!,
                                                 pluginView.get(.top)!,
                                                 pluginView.get(.bottom)!])
        
        pinnedView.set(.fillSuperView(pluginPinnedBaseView))
        landscapeConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                 pinnedView.get(.trailing)!,
                                                 pinnedView.get(.top)!,
                                                 pinnedView.get(.bottom)!])
        
        setLandscapeContraintAsDeactive()
    }
    
}

// TopBar related Methods
extension MeetingViewController {
    private func createTopbar() {
        let topbar = DyteMeetingHeaderView(meeting: self.meeting)
        self.view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"
        self.topBar = topbar
        addPotraitContraintTopbar()
        addLandscapeContraintTopbar()
    }
    
    private func addPotraitContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view), .top(self.view))
        portraitConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                self.topBar.get(.trailing)!,
                                                self.topBar.get(.top)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view) , .top(self.view))

        self.topBar.set(.height(0))
        landscapeConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                 self.topBar.get(.trailing)!,
                                                 self.topBar.get(.top)!,
                                                 self.topBar.get(.height)!])
        setLandscapeContraintAsDeactive()
    }

}



extension MeetingViewController : MeetingViewModelDelegate {
    
    func newPollAdded(createdBy: String) {
        if Shared.data.notification.newPollArrived.showToast {
            self.view.showToast(toastMessage: "New poll created by \(createdBy)", duration: 2.0, uiBlocker: false)
        }
    }
    
    func participantJoined(participant: DyteMeetingParticipant) {
        if Shared.data.notification.participantJoined.showToast {
            self.view.showToast(toastMessage: "\(participant.name) just joined", duration: 2.0, uiBlocker: false)
        }
    }
    
    func participantLeft(participant: DyteMeetingParticipant) {
        if Shared.data.notification.participantLeft.showToast {
            self.view.showToast(toastMessage: "\(participant.name) left", duration: 2.0, uiBlocker: false)
        }
    }
    
    
    func activeSpeakerChanged(participant: DyteMeetingParticipant) {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        // showAndHideActiveSpeaker()
    }
    
    func pinnedChanged(participant: DyteJoinedMeetingParticipant) {
        if self.viewModel.pinOrPluginModeIsActive() {
            if self.viewModel.pluginModeIsActive() == false {
                self.pinnedView.setParticipant(meeting: self.meeting, participant: participant)
            }
        }
    }
    
    func activeSpeakerRemoved() {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        //showAndHideActiveSpeaker()
    }
    
    private func showAndHideActiveSpeaker() {
        if let pinned = self.meeting.participants.pinned {
            self.pluginView.showPinnedView(participant: pinned)
        }else {
            self.pluginView.hideActiveSpeaker()
        }
    }
    
    private func getScreenShareTabButton(participants: [ParticipantsShareControl]) -> [ScreenShareTabButton] {
        var arrButtons = [ScreenShareTabButton]()
        for participant in participants {
            var image: DyteImage?
            if let _ = participant as? ScreenShareModel {
                //For
                image = DyteImage(image: ImageProvider.image(named: "icon_screen_share"))
            }else {
                if let strUrl = participant.image , let imageUrl = URL(string: strUrl) {
                    image = DyteImage(url: imageUrl)
                }
            }
            
            let button = ScreenShareTabButton(image: image, title: participant.name, id: participant.id)
            // TODO:Below hardcoding is not needed, We also need to scale down the image as well.
            button.btnImageView?.set(.height(20),
                                     .width(20))
            arrButtons.append(button)
        }
        return arrButtons
    }
    
    private func handleClicksOnPluginsTab(model: PluginButtonModel, at index: Int) {
        self.pluginView.show(pluginView:  model.plugin.getPluginView())
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    private func handleClicksOnScreenShareTab(model: ScreenShareModel, index: Int) {
        self.pluginView.showVideoView(participant: model.participant)
        self.pluginView.pluginVideoView.viewModel.refreshNameTag()
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    public func selectPluginOrScreenShare(id: String) {
        var index: Int = -1
        for button in self.pluginView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                self.pluginView.selectForAutoSync(button: button)
                break
            }
        }
    }
    
    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [ScreenShareTabButton])  {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            self.pluginView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button, isUserClick in
                guard let self = self else {return}
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    if self.pluginView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)
                    
                }else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if self.pluginView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: screenShare.id, tabType: .screenshare)
                    }
                    self.handleClicksOnScreenShareTab(model: screenShare, index: button.index)
                }
                for (index, element) in arrButtons.enumerated() {
                    element.isSelected = index == button.index ? true : false
                }
            }
        }
        self.pluginView.showAndHideActiveButtonListView(buttons: arrButtons)
    }
    
    private func showHidePluginPinnedAndScreenShareView() {
        if self.viewModel.pinOrPluginModeIsActive() {
            self.showPinnedPluginView(show: true, animation: true)
            if self.viewModel.pluginModeIsActive() {
                self.showPluginView(show: true)
            }
            else if self.viewModel.pinModeIsActive() {
                self.showPinnedView(show: true)
            }
        }else {
            self.showPinnedPluginView(show: false, animation: true)
        }
    }
    
    func refreshPluginsView() {
        self.showHidePluginPinnedAndScreenShareView()
        if self.viewModel.pluginModeIsActive() {
            let participants = self.viewModel.screenShareViewModel.arrScreenShareParticipants
            let arrButtons = self.getScreenShareTabButton(participants: participants)
            self.refreshPluginsButtonTab(pluginsButtonsModels: participants, arrButtons: arrButtons)
            if arrButtons.count >= 1 {
                var selectedIndex: Int?
                if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                    selectedIndex = Int(index)
                }
                if let index = selectedIndex {
                    if let pluginModel = participants[index] as? PluginButtonModel {
                        self.pluginView.show(pluginView: pluginModel.plugin.getPluginView())
                    }
                    else if let screenShare = participants[index] as? ScreenShareModel {
                        self.pluginView.showVideoView(participant: screenShare.participant)
                    }
                    self.loadGrid(fullScreen: false, animation: false, completion: {})
                }
            }
        } else {
            self.closefullscreen()
            if UIScreen.isLandscape() == false {
                self.fullScreenButton.isHidden = true
            }

            if self.viewModel.pinModeIsActive() {
                self.pluginView.setButtons(buttons: [ScreenShareTabButton](), selectedIndex: nil) {_,_  in}
                self.pinnedView.setParticipant(meeting: self.meeting, participant: self.meeting.participants.pinned!)
                self.loadGrid(fullScreen: false, animation: false, completion: {})
            } else {
                self.loadGrid(fullScreen: true, animation: false, completion: {})
            }
        }
       
        self.meetingGridPageBecomeVisible()
    }
    
    private func showPluginView(show: Bool) {
        self.pluginView.isHidden = !show
        self.pinnedView.isHidden = true
    }
    
    private func showPinnedView(show: Bool) {
        self.pinnedView.isHidden = !show
        self.pluginView.isHidden = true
    }
    
    private func showPinnedPluginView(show: Bool, animation: Bool) {
        self.showPinnedPluginViewAsPerOrientation(show: show)
        pluginPinnedBaseView.isHidden = !show
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                self.view.layoutIfNeeded()
            }
        }else {
            self.view.layoutIfNeeded()
        }
    }
    
    private func loadGrid(fullScreen: Bool, animation: Bool, completion:@escaping()->Void) {
        let arrModels = self.viewModel.arrGridParticipants
        if fullScreen == false {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
            
        }else {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForLandScape(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
            
        }
    }
    
    internal func refreshMeetingGridTile(participant: DyteMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = self.gridView.childView(index: index) {
                    peerContainerView.setParticipant(meeting: self.meeting, participant: arrModels[index].participant)
                    return
                }
            }
        }
    }
    
    private func meetingGridPageBecomeVisible() {
        
        if let participant = meeting.participants.pinned {
            self.refreshMeetingGridTile(participant: participant)
        }

        self.topBar.refreshNextPreviouButtonState()
    }
}



extension MeetingViewController: DyteNotificationDelegate {

    public func didReceiveNotification(type: DyteNotificationType) {
        switch type {
        case .Chat(let message):
            if Shared.data.notification.newChatArrived.playSound == true {
                viewModel.dyteNotification.playNotificationSound(type: type)
            }
            if Shared.data.notification.newChatArrived.showToast && message.isEmpty == false {
                self.view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false, showInBottom: true, bottomSpace: self.bottomBar.bounds.height)
            }
            NotificationCenter.default.post(name: Notification.Name("Notify_NewChatArrived"), object: nil, userInfo: nil)
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
            self.moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: self.meeting.chat.messages.count, totalsPolls: self.meeting.polls.polls.count))
            
        case .Poll:
            NotificationCenter.default.post(name: Notification.Name("Notify_NewPollArrived"), object: nil, userInfo: nil)
            if Shared.data.notification.newPollArrived.playSound == true {
                viewModel.dyteNotification.playNotificationSound(type: .Poll)
            }
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
            self.moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: self.meeting.chat.messages.count, totalsPolls: self.meeting.polls.polls.count))

        case .Joined:
            if Shared.data.notification.participantJoined.playSound == true {
                viewModel.dyteNotification.playNotificationSound(type: .Joined)
            }
        case .Leave:
            if Shared.data.notification.participantLeft.playSound == true {
                viewModel.dyteNotification.playNotificationSound(type: .Leave)
            }
        }
    }
    
    @objc
    public  func clearChatNotification() {
        self.moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension MeetingViewController: DyteLiveStreamEventsListener {

    
    public func onLiveStreamEnded() {
        
    }
    
    public func onLiveStreamEnding() {
        
    }
    
    public func onLiveStreamErrored() {
        
    }
    
    public func onLiveStreamStarted() {
        
    }
    
    public func onLiveStreamStarting() {
        
    }
    
    public func onLiveStreamStateUpdate(data: DyteLivestreamData) {
        
    }
    
    public func onStageCountUpdated(count: Int32) {
        if meeting.stage.stageStatus == StageStatus.offStage {
            let controller = LivestreamViewController(dyteMobileClient: meeting, completion: self.onFinishedMeeting)
            controller.view.backgroundColor = self.view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
            notificationDelegate?.didReceiveNotification(type: .Joined)
        }
    }
    
    public func onViewerCountUpdated(count: Int32) {
        
    }
}

extension MeetingViewController: DyteChatEventsListener {
    public func onChatUpdates(messages: [DyteChatMessage]) {
        
    }
    
    public func onNewChatMessage(message: DyteChatMessage) {
        if message.userId != meeting.localUser.userId {
            var chat = ""
            if  let textMessage = message as? DyteTextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            }else {
                if message.type == DyteMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == DyteMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message:chat))
        }
    }
}

// Notification Related Methods
extension MeetingViewController {
    func setupNotifications() {
        meeting.addChatEventsListener(chatEventsListener: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearChatNotification), name: Notification.Name("NotificationAllChatsRead"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onEndMettingForAllButtonPressed), name: DyteLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
    }
    // MARK: Notification Setup Functionality
    @objc private func onEndMettingForAllButtonPressed(notification: Notification) {
        self.viewModel.dyteSelfListner.observeSelfRemoved(update: nil)
    }
}


extension MeetingViewController {
    func addFullScreenView(contentView: UIView) {
        if fullScreenView == nil {
            fullScreenView =  FullScreenView()
            self.view.addSubview(fullScreenView)
            fullScreenView.set(.fillSuperView(self.view))
        }
        fullScreenView.backgroundColor = self.view.backgroundColor
        fullScreenView.isUserInteractionEnabled = true
        fullScreenView.set(contentView: contentView)
    }
    
    func removeFullScreenView() {
        fullScreenView.backgroundColor = .clear
        fullScreenView.isUserInteractionEnabled = false
        fullScreenView.removeContentView()
    }
}


class FullScreenView: UIView {
    let containerView = UIView()
    var isVisible: Bool = false
    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(self.containerView)
        self.containerView.set(.fillSuperView(self))
        self.setEdgeConstants()
    }
    
    func set(contentView: UIView) {
        isVisible = true
        containerView.addSubview(contentView)
        contentView.set(.fillSuperView(containerView))
    }
    
    func removeContentView() {
        isVisible = true
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setEdgeConstants()
    }
    
    private func setEdgeConstants() {
        self.containerView.get(.leading)?.constant = self.safeAreaInsets.left
        self.containerView.get(.trailing)?.constant = -self.safeAreaInsets.right
        self.containerView.get(.top)?.constant = self.safeAreaInsets.top
        self.containerView.get(.bottom)?.constant = -self.safeAreaInsets.bottom
    }
    
}



