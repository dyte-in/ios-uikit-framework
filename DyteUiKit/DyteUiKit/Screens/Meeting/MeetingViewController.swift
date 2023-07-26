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
        let tile = DyteParticipantTileView(mobileClient: meeting, participant: participant)
        self.tileView = tile
        self.addSubview(tile)
        tile.set(.fillSuperView(self))
    }
}

public class MeetingViewController: UIViewController {
    
   private var gridView: GridView<DyteParticipantTileContainerView>!
    let pluginView: PluginView
    private let gridBaseView = UIView()
    private let pluginBaseView = UIView()
    private let baseContentView = UIView()
    private let isDebugModeOn = DyteUiKit.isDebugModeOn
    
    private var isPluginOrScreenShareActive = false

    let viewModel: MeetingViewModel
    private let dyteMobileClient: DyteMobileClient
   // private lazy var pageControl: UIPageControl = createPageControl()

    private var topBar: DyteMeetingHeaderView!
    private var bottomBar: DyteMeetingControlBar!
    private let completion: ()->Void
    private var viewWillAppear = false
    
    private var moreButtonBottomBar: DyteControlBarButton?
    private var layoutContraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutContraintPluginBaseVariableHeight: NSLayoutConstraint!

    
    init(dyteMobileClient: DyteMobileClient, completion:@escaping()->Void) {
        //TODO: Check the local user passed now
        self.pluginView = PluginView(videoPeerViewModel:VideoPeerViewModel(mobileClient: dyteMobileClient, showScreenShareVideo: true, participant: dyteMobileClient.localUser))
        self.completion = completion
        self.viewModel = MeetingViewModel(dyteMobileClient: dyteMobileClient)
        self.dyteMobileClient = dyteMobileClient
        super.init(nibName: nil, bundle: nil)
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
        createTopbar()
        createBottomBar()
        createSubView()
        setInitialsConfiguration()
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
            
            showWaitingRoom(status: .rejected, time: 2) { [weak self] in
                guard let self = self else {return}
                self.viewModel.clean()
                self.completion()
            }
        }
        
        if self.dyteMobileClient.localUser.permissions.waitingRoom.canAcceptRequests {
            self.viewModel.waitlistEventListner.participantJoinedCompletion = {[weak self] participant in
                guard let self = self else {return}
                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0)
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
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            self.viewModel.refreshActiveParticipants()
            self.viewModel.trackOnGoingState()
        }
    }

    deinit {
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
        topbar.set(.sameLeadingTrailing(self.view))
        self.topBar = topbar
    }
    
    private func createBottomBar() {
        
        let controlBar =  DyteMeetingControlBar(meeting: self.dyteMobileClient, delegate: nil, presentingViewController: self, meetingViewModel: self.viewModel) {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.dyteMobileClient.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.completion()
        }

        self.moreButtonBottomBar = controlBar.moreButton
        
        self.view.addSubview(controlBar)
        controlBar.set(.sameLeadingTrailing(self.view),
                       .bottom(self.view))
        
        self.bottomBar = controlBar
    }
}



extension MeetingViewController : MeetingViewModelDelegate {
    func showWaitingRoom(status: WaitListStatus) {
        
    }
    
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
            
            let button = ScreenShareTabButton(image: image, title: participant.name)
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
    
    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [ScreenShareTabButton])  {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            self.pluginView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button in
                guard let self = self else {return}
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)
                    
                }else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
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
        self.pluginView.setButtons(buttons: buttons, selectedIndex: nil) {_ in}
        self.showPluginView(show: false, animation: true)
        if self.dyteMobileClient.participants.currentPageNumber == 0 {
            self.loadGrid(fullScreen: true, animation: true, completion: {})
        }
    }
    
    
    private func move(gridView:  GridView<DyteParticipantTileView>, toView: UIView) {
        gridView.removeFromSuperview()
        toView.addSubview(gridView)
        gridView.set(.fillSuperView(toView))
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
    static var schedule = false

    func refreshMeetingGrid() {
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
}






