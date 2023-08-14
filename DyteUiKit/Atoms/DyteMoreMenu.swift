//
//  DyteMoreMenu.swift
//  DyteUiKit
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import UIKit
import DyteiOSCore

public enum MenuType {
    case shareMeetingUrl
    case poll(notificationMessage:String)
    case chat(notificationMessage:String)
    case plugins
    case settings
    case particpants(notificationMessage:String)
    case recordingStart
    case recordingStop
    case muteAudio
    case muteVideo
    case pin
    case unPin
    case allowToJoinStage
    case denyToJoinStage
    case removeFromStage
    case kick
    case files
    case images
    case cancel
}


protocol BottomSheetModelProtocol {
    associatedtype IDENTIFIER
    var image: DyteImage {get}
    var title: String {get}
    var type: IDENTIFIER {get}
    var unreadCount: String {get}
    var onTap: (_ bottomSheet: BottomSheet) -> Void {get}
}

class UNReadCountView: UIView {

   private let title : DyteText = {
       let label = UIUTility.createLabel(text: "")
       label.font = UIFont.systemFont(ofSize: 12)
       return label
   }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        createSubView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(unReadCount: String) {
        if unReadCount.count > 0 {
            self.isHidden = false
        }else {
            self.isHidden = true
        }
        self.title.text = unReadCount
    }
    
    private func createSubView() {
        self.backgroundColor = tokenColor.brand.shade500
        self.addSubview(title)
        title.set(.sameLeadingTrailing(self, tokenSpace.space1),
                  .sameTopBottom(self, tokenSpace.space1))
        
    }
    
}

class BottomSheet: UIView {
    let selfTag = 89373
    private let baseStackView = UIUTility.createStackView(axis: .vertical, spacing: 0)
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let backgroundColorValue = DesignLibrary.shared.color.background.shade800
    let backgroundColorValueForLineSeparator = DesignLibrary.shared.color.background.shade700
    let tokenSpace = DesignLibrary.shared.space
    public var onHide: ((BottomSheet)->Void)?
    private let title: String?
    
    init(title: String? = nil, features: [some BottomSheetModelProtocol]) {
        self.title = title
        super.init(frame: .zero)
        self.addSubview(baseStackView)
        baseStackView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                       radius: borderRadiusType)
        baseStackView.set(.sameLeadingTrailing(self, tokenSpace.space1),
                          .bottom(self),
                          .top(self, tokenSpace.space4, .greaterThanOrEqual))
        
        baseStackView.backgroundColor = backgroundColorValue
        baseStackView.layoutMargins = UIEdgeInsets(top: 0, left: tokenSpace.space4, bottom: 0, right: 0)
        baseStackView.isLayoutMarginsRelativeArrangement = true
        if let title = title, title.count > 0 {
            baseStackView.addArrangedSubview(self.getTitleView(title: title))
        }
        
        for model in features {
            let button = getMenuButton(title: model.title, systemImage: model.image, unreadCount: model.unreadCount)
            button.button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            button.button.model = model
            baseStackView.addArrangedSubview(button.baseView)
        }
        self.tag = selfTag
    }
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden == false && self.frame.contains(point) {
            if self.baseStackView.frame.contains(point) {
                return super.hitTest(point, with: event)
            }
            DispatchQueue.main.async {
                // This is so that when this view say that touches are in this but not action sheet button.
                // then we have to consume these touches and current view should not be hidden before returning from this method else this will ignore these touches and passes down the hierarchy.
                self.hideSheet()
            }
            return self
        }
        return nil
    }
    
    public func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        self.set(.fillSuperView(view))
    }
    
    @objc private func buttonTapped(button: CustomButton) {
        // Perform additional actions here
        button.model?.onTap(self)
        self.hideSheet()
    }
    
    private func hideSheet() {
        self.isHidden = true
        self.onHide?(self)
    }
    
    class CustomButton: UIButton {
        var model: (any BottomSheetModelProtocol)?
    }
    
    private func getTitleView(title: String, needLine: Bool = true) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let title = UIUTility.createLabel(text: title, alignment: .center)
        view.addSubview(title)
        title.font = UIFont.systemFont(ofSize: 16)
        title.set(.sameLeadingTrailing(view), .sameTopBottom(view, tokenSpace.space4))
        if needLine {
            let lineView = UIView()
            view.addSubview(lineView)
            lineView.set(.leading(view),
                         .trailing(view, tokenSpace.space4),
                         .height(1),
                         .bottom(view))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return view
    }
    
    
    
    private func getMenuButton(title: String, systemImage: DyteImage, needLine: Bool = true, unreadCount: String = "") -> (baseView: UIView,button: CustomButton, notificationMessageView: UNReadCountView) {
        let color = DesignLibrary.shared.color.textColor.onBackground.shade900
        let view = UIView()
        view.isUserInteractionEnabled = false
        let imageView = UIUTility.createImageView(image: systemImage)
        imageView.tintColor = color
        let baseImageView = UIView()
        baseImageView.addSubview(imageView)
        
        imageView.set(.centerView(baseImageView),
                      .top(baseImageView, 0.0 , .greaterThanOrEqual),
                      .leading(baseImageView,0.0,.greaterThanOrEqual))
        let title = UIUTility.createLabel(text: title, alignment: .left)
        title.textColor = color
        view.addSubview(baseImageView)
        view.addSubview(title)
        baseImageView.set(.sameTopBottom(view, tokenSpace.space2), .leading(view), .width(30))
        title.set(.after(baseImageView, tokenSpace.space2), .centerY(baseImageView))
        
        let unreadCountView = UNReadCountView()
        view.addSubview(unreadCountView)
        unreadCountView.set(.after(title, tokenSpace.space2, .greaterThanOrEqual),
                            .trailing(view, tokenSpace.space2),
                            .centerY(title),
                            .height(tokenSpace.space5),
                            .width(tokenSpace.space5, .greaterThanOrEqual))
        unreadCountView.layer.cornerRadius = tokenSpace.space5/2.0
        unreadCountView.layer.masksToBounds = true
        unreadCountView.set(unReadCount: unreadCount)
        
        
        let viewBase = UIView()
        let fixedHeightView = UIView()
        viewBase.addSubview(fixedHeightView)
        fixedHeightView.set(.fillSuperView(viewBase),
                            .height(50))
        
        let button = CustomButton()
        viewBase.addSubview(button)
        button.set(.fillSuperView(viewBase))
        fixedHeightView.addSubview(view)
        
        view.set(.top(fixedHeightView, 0.0, .greaterThanOrEqual),
                 .centerY(fixedHeightView),
                 .leading(fixedHeightView),
                 .trailing(fixedHeightView, tokenSpace.space4, .greaterThanOrEqual))
        if needLine {
            let lineView = UIView()
            viewBase.addSubview(lineView)
            lineView.set(.leading(viewBase),
                         .trailing(viewBase, tokenSpace.space4),
                         .height(1),
                         .bottom(viewBase))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return (viewBase, button, unreadCountView)
    }
}

public class DyteMoreMenu: UIView {
    
    struct BottomSheetModel: BottomSheetModelProtocol {
        var unreadCount: String = ""
        
        var type: MenuType
        
        var image: DyteImage
        
        var title: String
        
        var onTap: (BottomSheet) -> Void
    }
    
    var bottomSheet: BottomSheet!
    let selfTag = 89372
    
    private var onSelect: (MenuType) -> ()
    
    public  init(title:String? = nil, features: [MenuType] , onSelect: @escaping (MenuType) -> ()) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        var model = [BottomSheetModel]()
        for feature in features {
            switch feature {
            case.files:
                model.append(BottomSheetModel(type: .files, image: DyteImage(image: ImageProvider.image(named: "icon_attach")), title: "File", onTap: { [weak self] bottomSheet in
                    guard let self = self else { return }
                    onSelect(feature)
                    self.hideSheet()
                }))
                
            case.images:
                model.append(BottomSheetModel(type: .images, image: DyteImage(image: ImageProvider.image(named: "icon_image")), title: "Image", onTap: { [weak self] bottomSheet in
                    guard let self = self else { return }
                    onSelect(feature)
                    self.hideSheet()
                }))
            case.shareMeetingUrl:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_chat_send")), title: "Share meeting", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .poll(let notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .unPin:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_unpin")), title: "Unpin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .muteAudio:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mute", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .pin:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_pin")), title: "Pin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .allowToJoinStage:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Allow to join Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .denyToJoinStage:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Revoke to join Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .removeFromStage:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_stage_leave")), title: "Remove from Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .muteVideo:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Turn off video", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .kick:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_kick")), title: "Kick", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .chat(let notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage,type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_chat")), title: "Chat", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .plugins:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_plugin")), title: "Plugin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .settings:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_setting")), title: "Settings", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .recordingStart:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_recording_start")), title: "Record", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .recordingStop:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_recording_stop")), title: "Stop", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .particpants(let notificationMessage):
                
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_participants")), title: "Participants", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .cancel:
                model.append(BottomSheetModel(type: feature, image: DyteImage(image: ImageProvider.image(named: "icon_cross")), title: "Cancel", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            }
        }
        bottomSheet = BottomSheet(title: title, features: model)
        bottomSheet.onHide = {[weak self] bottomSheet in
            guard let self = self else {return}
            self.hideSheet()
        }
        self.tag = selfTag
    }
    
    
    public func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        self.set(.fillSuperView(view))
        self.bottomSheet.show(on: self)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func hideSheet() {
        self.isHidden = true
    }
}
