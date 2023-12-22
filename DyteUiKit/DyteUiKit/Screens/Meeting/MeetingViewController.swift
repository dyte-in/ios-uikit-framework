//
//  MeetingViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 21/12/22.
//

import DyteiOSCore
import UIKit

struct Animations {
    static let gridViewAnimationDuration = 0.3
}

class DyteParticipantTileContainerView : UIView {
    var tileView: DyteParticipantTileView!
    
    func prepareForReuse() {
        tileView?.removeFromSuperview()
        tileView = nil
    }
    
    func setParticipant(meeting: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        prepareForReuse()
        let tile = DyteParticipantTileView(mobileClient: meeting, participant: participant, isForLocalUser: false, showScreenShareVideoView: false)
        self.tileView = tile
        self.addSubview(tile)
        tile.set(.fillSuperView(self))
    }
}

public class BaseViewController: UIViewController {
    let dyteSelfListner: DyteEventSelfListner!
    internal let dyteMobileClient: DyteMobileClient
    private var waitingRoomView: WaitingRoomView?

    
    init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
     func setUpReconnection(failed: @escaping()->Void, success: @escaping()->Void) {
        dyteSelfListner.observeMeetingReconnectionState { [weak self] state in
            guard let self = self else {return}
            switch state {
            case .failed:
                self.view.removeToast()
                let retryAction = UIAlertAction(title: "ok", style: .default) { action in
                    failed()
                }
                UIUTility.displayAlert(alertTitle: "Connection Lost!", message: "Please try again later", actions: [retryAction])
            case .success:
                success()
                self.view.showToast(toastMessage: "Connection Restored", duration: 2.0)
            case .start:
                self.view.showToast(toastMessage: "Reconnecting...", duration: -1)
            }
        }
    }
    
     func addWaitingRoom(completion:@escaping()->Void) {
        self.dyteSelfListner.waitListStatusUpdate = { [weak self] status in
            guard let self = self else {return}
            let callBack : ()-> Void = {
                completion()
            }
            showWaitingRoom(status: status, completion: callBack)
        }
        
        func showWaitingRoom(status: WaitListStatus, completion: @escaping()->Void) {
           waitingRoomView?.removeFromSuperview()
           if status != .none {
               let waitingView = WaitingRoomView(automaticClose: false, onCompletion: { [weak self] in
                   guard let self = self else {return}
                   completion()
               })
               waitingView.accessibilityIdentifier = "WaitingRoom_View"
               waitingView.backgroundColor = self.view.backgroundColor
               self.view.addSubview(waitingView)
               waitingView.set(.fillSuperView(self.view))
               self.view.endEditing(true)
               waitingRoomView = waitingView
               waitingView.show(status: status)
           }
       }
    }

}

public class MeetingViewController: BaseViewController {
    private var gridView: GridView<DyteParticipantTileContainerView>!
    let pluginView: PluginView
    private let gridBaseView = UIView()
    private let pluginBaseView = UIView()
    let baseContentView = UIView()
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    private var isPluginOrScreenShareActive = false
    
    let viewModel: MeetingViewModel
    
    private var topBar: DyteMeetingHeaderView!
    internal var bottomBar: DyteControlBar!
    
    internal let onFinishedMeeting: ()->Void
    private var viewWillAppear = false
    
    internal var moreButtonBottomBar: DyteControlBarButton?
    private var layoutContraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutContraintPluginBaseVariableHeight: NSLayoutConstraint!
    private var waitingRoomView: WaitingRoomView?

    init(dyteMobileClient: DyteMobileClient, completion:@escaping()->Void) {
        //TODO: Check the local user passed now
        self.pluginView = PluginView(videoPeerViewModel:VideoPeerViewModel(mobileClient: dyteMobileClient, participant: dyteMobileClient.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        self.onFinishedMeeting = completion
        self.viewModel = MeetingViewModel(dyteMobileClient: dyteMobileClient)
        super.init(dyteMobileClient: dyteMobileClient)

        notificationDelegate = self
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(self.view, self.view.safeAreaInsets.top))
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.accessibilityIdentifier = "Meeting_Base_View"
        self.view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        createTopbar()
        createBottomBar()
        createSubView()
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
        
        if self.dyteMobileClient.localUser.permissions.waitingRoom.canAcceptRequests {
            self.viewModel.waitlistEventListner.participantJoinedCompletion = {[weak self] participant in
                guard let self = self else {return}
                
                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                if self.dyteMobileClient.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            
            self.viewModel.waitlistEventListner.participantRequestRejectCompletion = {[weak self] participant in
                guard let self = self else {return}
                if self.dyteMobileClient.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            self.viewModel.waitlistEventListner.participantRequestAcceptedCompletion = {[weak self] participant in
                guard let self = self else {return}
                if self.dyteMobileClient.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
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
        }
    }
    
    public func refreshMeetingGrid() {
        if isDebugModeOn {
            print("Debug DyteUIKit | refreshMeetingGrid")
        }
        
        self.meetingGridPageBecomeVisible()
        for i in 0..<self.gridView.maxItems {
            if let peerView = self.gridView.childView(index: Int(i)) {
                peerView.prepareForReuse()
            }
        }
        
        let arrModels = self.viewModel.arrGridParticipants
        
        if isDebugModeOn {
            print("Debug DyteUIKIt | refreshing Finished")
        }
        
        if self.dyteMobileClient.participants.currentPageNumber == 0 {
            self.showPluginView(show: isPluginOrScreenShareActive, animation: false)
            self.loadGrid(fullScreen: !isPluginOrScreenShareActive, animation: true, completion: {
                populateGridChildViews(models: arrModels)
            })
        }else {
            self.showPluginView(show: false, animation: false)
            self.loadGrid(fullScreen: true, animation: true, completion: {
                populateGridChildViews(models: arrModels)
            })
        }
        
       
        func populateGridChildViews(models: [GridCellViewModel]) {
            for i in 0..<models.count {
                if let peerContainerView = self.gridView.childView(index: i) {
                    peerContainerView.setParticipant(meeting: self.dyteMobileClient, participant: models[i].participant)
                }
            }
            if isDebugModeOn {
                print("Debug DyteUIKit | Iterating for Items \(arrModels.count)")
                for i in 0..<models.count {
                    if let peerContainerView = self.gridView.childView(index: i), let tileView = peerContainerView.tileView {
                        print("Debug DyteUIKit | Tile View Exists \(tileView) \nSuperView \(tileView.superview)")
                    }
                }
            }
        }
    }
    
    internal func createBottomBar() {
        
        let controlBar =  DyteMeetingControlBar(meeting: self.dyteMobileClient, delegate: nil, presentingViewController: self, meetingViewModel: self.viewModel) {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.dyteMobileClient.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        self.moreButtonBottomBar = controlBar.moreButton
        
        self.view.addSubview(controlBar)
        controlBar.set(.sameLeadingTrailing(self.view),
                       .bottom(self.view))
        
        self.bottomBar = controlBar
    }

    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false

        if isDebugModeOn {
            print("DyteUIKit | MeetingViewController Deinit is calling ")
        }
    }
}

private extension MeetingViewController {
           
    private func setInitialsConfiguration() {
        self.topBar.nextPreviousButtonView.isHidden = true
    }
    
        
    private func createSubView() {
        self.view.addSubview(baseContentView)

        baseContentView.set(.sameLeadingTrailing(self.view),
                           .below(topBar),
                           .above(bottomBar))

        baseContentView.addSubview(pluginBaseView)
        baseContentView.addSubview(gridBaseView)
        
        pluginBaseView.set(.sameLeadingTrailing(baseContentView),
                      .top(baseContentView))
        pluginBaseView.accessibilityIdentifier = "Grid_Plugin_View"
        layoutContraintPluginBaseVariableHeight = NSLayoutConstraint(item: pluginBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.7, constant: 0)
        layoutContraintPluginBaseZeroHeight = NSLayoutConstraint(item: pluginBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)
        layoutContraintPluginBaseZeroHeight.isActive = true
        layoutContraintPluginBaseVariableHeight.isActive = false
        
        gridBaseView.set(.sameLeadingTrailing(baseContentView),
                      .below(pluginBaseView),
                      .bottom(baseContentView))
        
        gridView = GridView(showingCurrently: 9, getChildView: {
             
            return DyteParticipantTileContainerView()
        })
        gridBaseView.addSubview(gridView)
        gridView.set(.fillSuperView(gridBaseView))
        pluginBaseView.addSubview(pluginView)
        pluginView.set(.fillSuperView(pluginBaseView))
    }
    
    private func createTopbar() {
        let topbar = DyteMeetingHeaderView(meeting: self.dyteMobileClient)
        self.view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"

        topbar.set(.sameLeadingTrailing(self.view))
        self.topBar = topbar
    }
}




extension MeetingViewController : MeetingViewModelDelegate {

    
    func activeSpeakerChanged(participant: DyteMeetingParticipant) {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
       // showAndHideActiveSpeaker()
    }
    
    func pinnedChanged(participant: DyteMeetingParticipant) {
        
    }
    
    func activeSpeakerRemoved() {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        //showAndHideActiveSpeaker()
    }
    
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant) {
        //showAndHideActiveSpeaker()
        updatePin(show: false, participant: participant)
    }
    
    private func showAndHideActiveSpeaker() {
        let pluginViewIsVisible = isPluginOrScreenShareActive
        if let pinned = self.dyteMobileClient.participants.pinned, pluginViewIsVisible {
            self.pluginView.showPinnedView(participant: pinned)
        }else {
          self.pluginView.hideActiveSpeaker()
        }
    }
    
    func meetingRecording(start: Bool) {
        self.topBar.recordingView.meetingRecording(start: start)
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
        var find = false
        for button in self.pluginView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                self.pluginView.selectForAutoSync(button: button)
                find = true
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
                        self.dyteMobileClient.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)
                    
                }else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if self.pluginView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.dyteMobileClient.meta.syncTab(id: screenShare.id, tabType: .screenshare)
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
        
    func refreshPluginsView() {
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
                self.showPlugInView()
            }
        } else {
            self.hidePlugInView(tab: arrButtons)
        }
        self.meetingGridPageBecomeVisible()
    }
    
    private func showPluginView(show: Bool, animation: Bool) {
        layoutContraintPluginBaseVariableHeight.isActive = show
        layoutContraintPluginBaseZeroHeight.isActive = !show
        pluginBaseView.isHidden = !show
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
            self.gridView.settingFramesForHorizontal(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                completion()
            }
        }else {
            self.gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                completion()
            }
        }
    }
    
    private func showPlugInView() {
        // We need to move gridview to Starting View
        isPluginOrScreenShareActive = true
        if self.dyteMobileClient.participants.currentPageNumber == 0 {
            //We have to only show PluginView on page == 0 only
            self.showPluginView(show: true, animation: true)
            self.loadGrid(fullScreen: false, animation: true, completion: {})
        }
    }
    
    private func hidePlugInView(tab buttons: [ScreenShareTabButton]) {
        
        
        // No need to show any plugin or share view
        isPluginOrScreenShareActive = false
        self.pluginView.setButtons(buttons: buttons, selectedIndex: nil) {_,_  in}
        self.showPluginView(show: false, animation: true)
        if self.dyteMobileClient.participants.currentPageNumber == 0 {
            self.loadGrid(fullScreen: true, animation: true, completion: {})
        }
    }
    
    func updatePin(show:Bool, participant: DyteMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerView = self.gridView.childView(index: index)?.tileView {
                    peerView.pinView(show: show)
                }
            }
        }
        
    }
    
    func refreshMeetingGridTile(participant: DyteMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = self.gridView.childView(index: index) {
                    peerContainerView.setParticipant(meeting: self.dyteMobileClient, participant: arrModels[index].participant)
                    return
                }
            }
        }
    }
   
    private func meetingGridPageBecomeVisible() {
        
        if let participant = dyteMobileClient.participants.pinned {
            self.refreshMeetingGridTile(participant: participant)
        }

        let nextPagePossible = self.dyteMobileClient.participants.canGoNextPage
        let prevPagePossible = self.dyteMobileClient.participants.canGoPreviousPage

        if !nextPagePossible && !prevPagePossible {
            //No page view to be shown
            self.topBar.nextPreviousButtonView.isHidden = true
        } else {
            self.topBar.nextPreviousButtonView.isHidden = false

            self.topBar.nextPreviousButtonView.nextButton.isEnabled = nextPagePossible
            self.topBar.nextPreviousButtonView.previousButton.isEnabled = prevPagePossible
            self.topBar.nextPreviousButtonView.nextButton.hideActivityIndicator()
            self.topBar.nextPreviousButtonView.previousButton.hideActivityIndicator()
            self.topBar.setNextPreviousText(first: Int(self.dyteMobileClient.participants.currentPageNumber), second: Int(self.dyteMobileClient.participants.pageCount) - 1)
        }
    }
}



extension MeetingViewController: DyteNotificationDelegate {
    func didReceiveNotification(type: DyteNotificationType) {
        switch type {
        case .Chat, .Poll:
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
            viewModel.dyteNotification.playNotificationSound(type: .Chat)
        case .Joined, .Leave:
            viewModel.dyteNotification.playNotificationSound(type: .Joined)
        }
    }
    
    func clearChatNotification() {
        self.moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension MeetingViewController: DyteLiveStreamEventsListener {
    public func onJoinRequestAccepted(peer: StagePeer) {
        
    }
    
    public func onJoinRequestRejected(peer: StagePeer) {
        
    }
    
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
        if dyteMobileClient.stage.stageStatus == StageStatus.offStage {
            let controller = LivestreamViewController(dyteMobileClient: dyteMobileClient, completion: self.onFinishedMeeting)
            controller.view.backgroundColor = self.view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
            notificationDelegate?.didReceiveNotification(type: .Joined)
        }
    }
    
    public func onStageRequestsUpdated(requests: [StagePeer]) {
        
    }
    
    public func onViewerCountUpdated(count: Int32) {
        
    }
    
    
}
extension MeetingViewController {
    func setupNotifications() {
           NotificationCenter.default.addObserver(self, selector: #selector(self.onEndMettingForAllButtonPressed), name: DyteLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
       }
       // MARK: Notification Setup Functionality
       @objc private func onEndMettingForAllButtonPressed(notification: Notification) {
           self.viewModel.dyteSelfListner.observeSelfRemoved(update: nil)
       }
}





