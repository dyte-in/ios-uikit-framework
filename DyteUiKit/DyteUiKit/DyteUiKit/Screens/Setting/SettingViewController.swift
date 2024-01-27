//
//  SettingViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 07/12/22.
//

import DyteiOSCore
import UIKit
import AVFAudio

public class SettingViewController: DyteBaseViewController, SetTopbar {
    public  var shouldShowTopBar: Bool = true
    
    public var topBar: DyteNavigationBar = DyteNavigationBar(title: "Settings")
    let baseView: BaseView = BaseView()
    let selfPeerView: DyteParticipantTileView

    let spaceToken = DesignLibrary.shared.space
    let borderRadius = DesignLibrary.shared.borderRadius

    private let nameTagTitle: String
    
    private var cameraDropDown: DyteDropdown<CameraPickerCellModel>!
    private var speakerDropDown: DyteDropdown<DyteAudioPickerCellModel>!
    private var audioSelectionView: DyteCustomPickerView<DytePickerModel<DyteAudioPickerCellModel>>?

    
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    private let completion: (()->Void)?
    
   public init(nameTag: String, dyteMobileClient: DyteMobileClient, completion:(()->Void)? = nil) {
        nameTagTitle = nameTag
        self.completion = completion
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: dyteMobileClient, participant: dyteMobileClient.localUser, showSelfPreviewVideo: true))
        super.init(dyteMobileClient: dyteMobileClient)
        
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(self.view, self.view.safeAreaInsets.top))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
         super.viewDidLoad()
         createSubviews()
         self.setTag(name: nameTagTitle)
         self.addTopBar(dismissAnimation: true) { [weak self] in
            guard  let self = self else {return}
            self.completion?()
        }
         loadSelfVideoView()
         self.view.backgroundColor =  backgroundColor
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc
    private func routeChanged(notification: Notification) {
        if self.speakerDropDown != nil {
            refreshAudioOutputDropDown()
        }
    }
    
    private func refreshAudioOutputDropDown() {
        let metaData = self.getSpeakerDropDownData()
        self.speakerDropDown.refresh(selectedIndex: UInt(metaData.selectedIndex), options: metaData.devicesModel)
        if self.speakerDropDown.selectedState {
            self.audioSelectionView?.refresh(list: metaData.devicesModel, selectedIndex: UInt(metaData.selectedIndex))
        }
    }

    private func setTag(name: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }
    private func createSubviews() {
        self.view.addSubview(baseView)
        baseView.set(.leading(self.view , spaceToken.space8, .greaterThanOrEqual ),
                     .centerView(self.view),
                     .top(self.view, spaceToken.space8, .greaterThanOrEqual))
        baseView.addSubview(selfPeerView)
       
        selfPeerView.clipsToBounds = true
        
        let equalWidthConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self.view, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
        let equalHeightConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: self.view, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)

        
        selfPeerView.set(.top(baseView),
                      .sameLeadingTrailing(baseView, spaceToken.space6))
       
        portraitConstraints.append(contentsOf: [equalWidthConstraintPeerView,
                                                equalHeightConstraintPeerView,
                                                selfPeerView.get(.top)!,
                                                selfPeerView.get(.leading)!,
                                                selfPeerView.get(.trailing)!])
        
        let equalWidthConstraintPeerViewLandscape =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self.view, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.4).getConstraint(for: selfPeerView)
        
        let equalHeightConstraintPeerViewLandscape =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: self.view, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)

        selfPeerView.set(.top(baseView),
                      .sameLeadingTrailing(baseView, spaceToken.space6))

        landscapeConstraints.append(contentsOf: [equalWidthConstraintPeerViewLandscape,
                                                equalHeightConstraintPeerViewLandscape,
                                                selfPeerView.get(.top)!,
                                                selfPeerView.get(.leading)!,
                                                selfPeerView.get(.trailing)!])

        applyConstraintAsPerOrientation()

        
        let btnStackView = createDropdownStackView()
        baseView.addSubview(btnStackView)
        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .sameLeadingTrailing(baseView),
                         .bottom(baseView))
    }
    
    private  func createDropdownStackView() -> BaseStackView {
        let stackView = DyteUIUTility.createStackView(axis: .vertical, spacing: spaceToken.space4)
        createDropDowns()
        if meeting.localUser.permissions.media.canPublishVideo && meeting.localUser.videoEnabled {
            stackView.addArrangedSubviews(cameraDropDown)
        }
        
        stackView.addArrangedSubviews(speakerDropDown)

        return stackView
    }
    
    private func createDropDowns() {
        self.cameraDropDown = createCameraDropDown()
        self.speakerDropDown = createAudioDropDown()
    }
    
    private func createCameraDropDown() -> DyteDropdown<CameraPickerCellModel> {
        let currentCameraSelectedDevice: VideoDeviceType? = meeting.localUser.getSelectedVideoDevice()?.type
        
        let cameraDropDown =  DyteDropdown(rightImage: DyteImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Camera", options: [CameraPickerCellModel(name: "Front camera", deviceType: .front) ,CameraPickerCellModel(name: "Back camera", deviceType: .rear)], selectedIndex: currentCameraSelectedDevice == .front ? 0 : 1) { [weak self] dropDown in
            guard let self = self else {return}
            let currentSelectedDevice: VideoDeviceType? = self.meeting.localUser.getSelectedVideoDevice()?.type
           
            let picker = DyteCustomPickerView.show(model: DytePickerModel(title: dropDown.heading, selectedIndex: currentSelectedDevice == .front ? 0 : 1, cells: dropDown.options), on: self.view)
            picker.onSelectRow = { [weak self] picker, index  in
                guard let self = self else {return}
                let currentSelectedDevice = picker.options[index]
                self.toggleCamera(mobileClient: self.meeting, selectDevice: currentSelectedDevice.deviceType)
                dropDown.selectOption(index: currentSelectedDevice.deviceType == .front ? 0 : 1)
            }
            picker.onCancelButtonClick = { [weak self] _ in
                guard let self = self else {return}
                self.toggleCamera(mobileClient: self.meeting, selectDevice: currentSelectedDevice)
                dropDown.selectOption(index: currentSelectedDevice == .front ? 0 : 1)
            }
        }
        return cameraDropDown
    }
    
    private func getSpeakerDropDownData() -> (devicesModel: [DyteAudioPickerCellModel], selectedIndex: Int) {
        func getDevices() -> [DyteAudioPickerCellModel] {
            let audioDevices = self.meeting.localUser.getAudioDevices()
            var deviceModels = [DyteAudioPickerCellModel]()
            for device in audioDevices {
                deviceModels.append(DyteAudioPickerCellModel(name: device.type.displayName, deviceType: device.type))
            }
            return deviceModels
        }
        
        func selectedIndex(current: AudioDeviceType?, deviceModels: [DyteAudioPickerCellModel]) -> Int {
            var count = -1
            for deviceModel in deviceModels {
                count += 1
                if deviceModel.deviceType == current {
                    return count
                }
            }
            return count
        }
        let currentAudioSelectedDevice: AudioDeviceType? = self.meeting.localUser.getSelectedAudioDevice()?.type
        let devices = getDevices()
        return (devices, selectedIndex(current: currentAudioSelectedDevice, deviceModels: devices))
    }
    private func createAudioDropDown() -> DyteDropdown<DyteAudioPickerCellModel> {
        
        let metaData = getSpeakerDropDownData()
        let speakerDropDown =  DyteDropdown(rightImage: DyteImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Speaker (output)", options: metaData.devicesModel, selectedIndex:UInt(metaData.selectedIndex)) { [weak self] dropDown in
            guard let self = self else {return}
            let metaData = getSpeakerDropDownData()
            let audioDevices = self.meeting.localUser.getAudioDevices()
            
            let picker = DyteCustomPickerView.show(model: DytePickerModel(title: dropDown.heading, selectedIndex: UInt(metaData.selectedIndex), cells: dropDown.options), on: self.view)
            picker.onSelectRow = { [weak self] picker, index  in
                guard let self = self else {return}
                let currentSelectedDevice = picker.options[index]
                for device in audioDevices {
                    if currentSelectedDevice.deviceType == device.type {
                        self.meeting.localUser.setAudioDevice(dyteAndroidDevice: device)
                        dropDown.selectOption(index: UInt(index))
                    }
                }
            }
            picker.onDoneButtonClick = { [weak dropDown]  picker in
                dropDown?.selectedState = false
            }
            picker.onCancelButtonClick = {[weak dropDown]  picker in
                dropDown?.selectedState = false
            }
            self.audioSelectionView = picker
        }
        return speakerDropDown
    }
    
    private func toggleCamera(mobileClient: DyteMobileClient, selectDevice: VideoDeviceType?) {
        let videoDevices = mobileClient.localUser.getVideoDevices()
        let currentSelectedDevice: VideoDeviceType? = mobileClient.localUser.getSelectedVideoDevice()?.type
       
        if currentSelectedDevice == .front && selectDevice == .rear {
            if let device = getVideoDevice(type: .rear) {
                mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
            }
        } else if currentSelectedDevice == .rear && selectDevice == .front  {
            if let device = getVideoDevice(type: .front) {
                mobileClient.localUser.setVideoDevice(dyteVideoDevice: device)
            }
        }
        
        func getVideoDevice(type: VideoDeviceType) -> DyteVideoDevice? {
            for device in videoDevices {
                if device.type == type {
                    return device
                }
            }
            return nil
        }
    }
    
    private func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
    
    deinit {
        print("Debug DyteUIKit | SettingViewController deinit is calling")
    }
    
}
