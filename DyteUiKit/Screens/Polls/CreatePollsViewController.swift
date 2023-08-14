//
//  CreatePollsViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 12/01/23.
//

import UIKit
import DyteiOSCore

class RadioTypeImage {
    var selectedImage: DyteImage
    var normalImage: DyteImage
    init(selectedImage: DyteImage, normalImage: DyteImage) {
        self.selectedImage = selectedImage
        self.normalImage = normalImage
    }
}

class AutoSizingTextView: UIView {
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let backGroundColor = DesignLibrary.shared.color.background.shade700
    let textColor = DesignLibrary.shared.color.textColor.onBackground.shade600
    
    let textView : UITextView = {return UITextView()}()

    let maxHeight:CGFloat
    
    let minimumHeight: CGFloat
    
    
    private var isMaxHeightConstraintSet = false
    private  var placeHolderLabel : UILabel!

    var maxHeightAchieved: Bool = false {
        didSet {
            if maxHeightAchieved == true {
                if isMaxHeightConstraintSet == false {
                    isMaxHeightConstraintSet = true
                    if let heightConstraint = textView.get(.height) {
                        textView.removeConstraint(heightConstraint)
                    }
                    textView.set(.height(textView.intrinsicContentSize.height))
                    self.textView.isScrollEnabled = true
                }
            } else {
                textView.isScrollEnabled = false
                isMaxHeightConstraintSet = false
                if let heightConstraint = textView.get(.height) {
                    textView.removeConstraint(heightConstraint)
                }
                
                textView.set(.height( max(minimumHeight,textView.intrinsicContentSize.height)))
            }
        }
    }
    
    init(maxheight height: CGFloat, minHeight: CGFloat = 40, placeHolderText: String = "Enter some text...") {
        maxHeight = height
        minimumHeight = minHeight
        super.init(frame: .zero)
        createSubView(placeHolderText: placeHolderText)
    }
    
    func createSubView(placeHolderText: String) {
        self.addSubview(textView)
        textView.set(.fillSuperView(self), .height(minimumHeight))
        textView.delegate = self
        textView.textColor = textColor
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 12)
        placeHolderLabel = createPlaceholderLabel(text: placeHolderText)
        textView.addSubview(placeHolderLabel)
        placeHolderLabel.set(.sameLeadingTrailing(textView, 5),
                             .top(textView, (textView.font?.pointSize)! / 2))
        placeHolderLabel.isHidden = !textView.text.isEmpty
        textView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                   radius: borderRadiusType)
        textView.backgroundColor = backGroundColor

    }
    
    func setPlaceHolder(text: String) {
        placeHolderLabel.text = text
    }
    
    func createPlaceholderLabel(text: String) -> UILabel {
       let placeholderLabel = UILabel()
           placeholderLabel.text = text
           placeholderLabel.font = .italicSystemFont(ofSize: (textView.font?.pointSize)!)
           placeholderLabel.sizeToFit()
        placeholderLabel.textColor = textColor
        return placeholderLabel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension AutoSizingTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
        if textView.contentSize.height >= maxHeight {
            maxHeightAchieved = true
        }else {
            maxHeightAchieved = false
        }
    }
}

class AutoSizingTitleTextView: BaseMoluculeView {
    let gapBetweenTitleAndTextView:CGFloat = 8
        
    let lblHeader: DyteText = { return UIUTility.createLabel(text: "", alignment: .left) }()
    let textView: AutoSizingTextView
    let lblError: DyteText = { return UIUTility.createLabel(text: "" , alignment: .left) }()

    init(headerTitle: String, placeHolderText: String) {
        textView = AutoSizingTextView(maxheight: 100, minHeight: 68, placeHolderText: placeHolderText)
        super.init(frame: .zero)
        self.createSubviews()
        lblHeader.text = headerTitle
        self.textView.setPlaceHolder(text: placeHolderText)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubviews() {
        let stackView = UIUTility.createStackView(axis: .vertical, spacing: gapBetweenTitleAndTextView)
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
        stackView.addArrangedSubviews(lblHeader, textView, lblError)
        lblError.isHidden = true
    }
}

class AddOptions: BaseMoluculeView {
   
    let btnAdd: DyteButton = {
        let button = DyteButton(style: .line, dyteButtonState: .active)
        button.setTitle("Add Options", for: .normal)
        return button
    }()
    private var textFields = [TextFieldBaseView]()
    let verticalGap: CGFloat = DesignLibrary.shared.space.space2
    let minimumOptionsToBeShown = 2
    let emptyTextFieldError = "Please insert voting option text"
    let tokenSpace = DesignLibrary.shared.space
    var textFiledCount = 0
    
    let lblErrorColor = DesignLibrary.shared.color.status.danger
    let textFieldBackgroundColorToken = DesignLibrary.shared.color.background.shade700
    
    let stackView: UIStackView
    
    init() {
        stackView = UIUTility.createStackView(axis: .vertical, spacing: verticalGap)
        super.init(frame: .zero)
        createSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubviews() {
        self.addSubview(stackView)
        self.addSubview(btnAdd)
        stackView.set(.top(self),
                      .sameLeadingTrailing(self))
        btnAdd.set(.below(stackView,verticalGap),
                   .sameLeadingTrailing(self),
                   .bottom(self))
        btnAdd.addTarget(self, action: #selector(addButtonClick(sender:)), for: .touchUpInside)
        atoms.append(btnAdd)

        var heading: String?
        for i in 0..<minimumOptionsToBeShown {
            textFiledCount += 1
            heading = nil
            if i == 0 {
              heading = "Options"
            }
            let textFieldBase = addAndSetTextField(heading: heading, placeHolderText: "Option \(textFiledCount)", needRemoveButton: false)
            stackView.addArrangedSubview(textFieldBase)
            textFieldBase.removeButton?.setClickAction(click: {  [weak self, unowned textFieldBase] _ in
                guard let self = self else {return}
                self.stackView.removeFully(view: textFieldBase)
                if let index = self.textFields.firstIndex(of: textFieldBase) {
                    self.textFields.remove(at: index)
                    self.textFiledCount -= 1
                }
            })

        }
    }
    
    @objc func addButtonClick(sender: DyteButton) {
        if checkAndShowError() {
            return
        }
        textFiledCount += 1
        let textFieldBase = addAndSetTextField(heading: nil, placeHolderText: "Option \(textFiledCount)", needRemoveButton: true)
        stackView.addArrangedSubview(textFieldBase)
        textFieldBase.removeButton?.setClickAction(click: {  [weak self, unowned textFieldBase] _ in
            guard let self = self else {return}
            self.stackView.removeFully(view: textFieldBase)
            if let index = self.textFields.firstIndex(of: textFieldBase) {
                self.textFields.remove(at: index)
                self.textFiledCount -= 1
            }
        })
    }
    
    private func addAndSetTextField(heading: String?, placeHolderText: String, needRemoveButton: Bool) -> TextFieldBaseView {
        let result = addTextField(heading: heading, text: "", needRemoveButton: needRemoveButton)
        let textField = result.textField
        textField.lblError.font = UIFont.systemFont(ofSize: 12)
        textField.lblError.textColor = lblErrorColor
        textField.setPlaceHolder(text: placeHolderText)
        textField.delegate = self
        textFields.append(result)
        atoms.append(textField)
        return result
    }
    
    private func checkAndShowError()-> Bool {
        for textFieldBase in textFields {
            let textField = textFieldBase.textField
            let isEmpty = textField.text?.isEmpty ?? true
            if isEmpty {
                textField.populateError(text: emptyTextFieldError)
                textField.lblError.alpha = 0.2
                UIView.animate(withDuration: 0.2) {
                    textField.lblError.alpha = 1.0
                }
                return true
            }else {
                textField.populateError()
            }
        }
        return false
    }
    
    func getText(index: Int) -> String? {
        if index < 0 && index >= textFields.count {
            return nil
        }
        return textFields[index].textField.text
    }
    
    func getAllOptions() -> [String] {
        var result = [String]()
        textFields.forEach { textField in
            if let text = textField.textField.text, text.isEmpty == false {
                result.append(text)
            }
        }
        return result
    }
    
    class TextFieldBaseView: UIView {
        let textField: DyteTextField
        let removeButton: DyteButton?
        init(textField: DyteTextField, removeButton: DyteButton?) {
            self.textField = textField
            self.removeButton = removeButton
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    private func addTextField(heading: String?, text: String, needRemoveButton: Bool) -> TextFieldBaseView {
        let baseView = UIView()
        let textField = DyteTextField(textFieldBackgroundColorToken: textFieldBackgroundColorToken)
        textField.errorLabelValidation = { [weak self] (text: String?, textField: DyteTextField) in
            guard let self = self else {return}
            if let text = text, text.count >= 1 {
                textField.populateError()
            }else {
                textField.populateError(text: self.emptyTextFieldError)
            }
        }
        textField.text = text
        textField.populateText(headerText: heading)
        baseView.addSubview(textField)
        
        textField.set(.sameTopBottom(baseView))
        var removalButton: DyteButton? = nil
        if needRemoveButton {
            let buttonToRemove = DyteButton(style: .line, size: .small)
            buttonToRemove.setTitle(" - ", for: .normal)
            baseView.addSubview(buttonToRemove)
            textField.set(.leading(baseView))
            buttonToRemove.set(.centerY(textField),
                               .top(baseView, tokenSpace.space0, .greaterThanOrEqual),
                               .after(textField, tokenSpace.space2),
                               .trailing(baseView))
            buttonToRemove.setClickAction { [weak self, unowned baseView] button in
                guard let self = self else {return}
                self.stackView.removeFully(view: baseView)
            }
            removalButton = buttonToRemove
        }else {
            textField.set(.sameLeadingTrailing(baseView))
        }
        let textFieldBase = TextFieldBaseView(textField: textField, removeButton: removalButton)
        textFieldBase.addSubview(baseView)
        baseView.set(.fillSuperView(textFieldBase))
        return textFieldBase
    }
}
extension AddOptions : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
}

class SelectionView: UIView {
    let spaceToken = DesignLibrary.shared.space
    let imageView:BaseImageView = { return BaseImageView()}()
    let title: DyteText = {
        let label = UIUTility.createLabel(alignment: .left)
        label.numberOfLines = 0
        return label
    }()
    private let radioImage: RadioTypeImage
    var index: Int = 0
    private var clickAction: (SelectionView)->Void
    
    init(radioImage: RadioTypeImage, title: String, onClick:@escaping(SelectionView)->Void) {
        self.radioImage = radioImage
        self.title.text = title
        self.clickAction = onClick
        super.init(frame: .zero)
        createSubView()
        self.setSelected(selected: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubView() {
        self.addSubview(imageView)
        self.addSubview(title)
        imageView.set(.leading(self),
                      .top(self, 0.0 , .greaterThanOrEqual),
                      .bottom(self, 0.0, .greaterThanOrEqual),
                      .centerY(title))
        title.set(.after(imageView,spaceToken.space2),
                  .top(self, 0.0, .greaterThanOrEqual),
                  .centerY(self),
                  .trailing(self, 0.0, .greaterThanOrEqual))
    }
    
    var isSelected: Bool = false {
        didSet {
            self.setSelected(selected: isSelected)
        }
    }
    
    private func setSelected(selected: Bool) {
        if selected == true {
            self.imageView.setImage(image: self.radioImage.selectedImage)
        }else {
            self.imageView.setImage(image: self.radioImage.normalImage)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        clickAction(self)
    }
}

protocol SelectionModel {
    var image: RadioTypeImage {get}
    var title: String {get}
    var isSelected: Bool {get}
}

enum VotePermissionType {
    case anonymous
    case hideResultBeforeVoting
}

class ListSelectionModel: SelectionModel {
    let image: RadioTypeImage
    let title: String
    let permission: VotePermissionType
    let isSelected: Bool
    init(image: RadioTypeImage, title: String, permission: VotePermissionType, isSelected: Bool) {
        self.image = image
        self.title = title
        self.permission = permission
        self.isSelected = isSelected
    }
}

enum SelectionType {
    case radio
    case multiple
}

class ListSelectionView<Model: SelectionModel>: UIView {
    let spaceToken = DesignLibrary.shared.space
    let models: [Model]
    let titleLabel: DyteText = {return UIUTility.createLabel(alignment: .left)}()
    let selectionType : SelectionType
    
    private let stackView = UIUTility.createStackView(axis: .vertical, spacing: 4)
    private let stackViewSelectionView = UIUTility.createStackView(axis: .vertical, spacing: 4)

    private var arrSelectionView = [SelectionView]()
    
    init(models: [Model], title: String , selectionType: SelectionType = .multiple) {
        self.models = models
        self.selectionType = selectionType
        super.init(frame: .zero)
        titleLabel.text = title
        createSubView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubView() {
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
        self.arrSelectionView = createListView(on: stackViewSelectionView)
        stackView.addArrangedSubviews(titleLabel,stackViewSelectionView)
    }
    
    private func createListView(on stackView: UIStackView) -> [SelectionView] {
        var arrResult = [SelectionView]()
        var index = 0
        for model in models {
            let view = self.get(image: model.image, title: model.title, isSelected: model.isSelected)
            view.index = index
            stackView.addArrangedSubview(view)
            arrResult.append(view)
            index += 1
        }
        return arrResult
    }
    
    private func get(image: RadioTypeImage, title: String, isSelected: Bool) -> SelectionView {
        let view  = SelectionView(radioImage: image, title: title) { [weak self] selectionView in
            guard let self = self else { return }
            if self.selectionType == .radio {
                self.selectView(at: selectionView.index)

            }else {
                selectionView.isSelected = !selectionView.isSelected
            }
        }
        view.isSelected = isSelected
        return view
    }
    
    private func selectView(at index: Int) {
        var key = 0
        for view in arrSelectionView {
            if key == index {
                view.isSelected = true
            }else {
                view.isSelected = false
            }
            key += 1
        }
    }
    
   public func getCurrentSelectedIndex() -> [Int]? {
        var index: Int = 0
        var result = [Int]()
        for view in arrSelectionView {
            if view.isSelected == true {
                result.append(index)
            }
            index += 1
        }
       return result.count > 0 ? result : nil
    }
}


class CreatePollView: UIView {
    
    let space = DesignLibrary.shared.space

    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeCreateView ?? .rounded

    let backGroundColor = DesignLibrary.shared.color.background.shade900
  
    
    let verticalSpacingBetweenElemements = DesignLibrary.shared.space.space4
    
    let lblHeader: DyteText = {
        let label = UIUTility.createLabel(text: "Create Poll", alignment: .left)
        label.font = UIFont.systemFont(ofSize: 20)
        return label
    }()
    
    let askQuestionTextView : AutoSizingTitleTextView = {
        let textView = AutoSizingTitleTextView(headerTitle: "Question", placeHolderText: "Ask a question")
        textView.lblError.text = "Please insert valid question to be asked in poll"
        textView.lblError.textColor = DesignLibrary.shared.color.status.danger
        textView.lblError.font = UIFont.systemFont(ofSize: 12)
        return textView
    }()
    
    let addOptionView: AddOptions = { return AddOptions() }()
    
    let permissionSelectionView: ListSelectionView = {
        let selectedImage = DyteImage(image: ImageProvider.image(named: "icon_radiobutton_selected"))
        let unSelectedImage = DyteImage(image: ImageProvider.image(named: "icon_radiobutton_unselected"))
        var model = [ListSelectionModel]()
        
        model.append(ListSelectionModel(image: RadioTypeImage(selectedImage: selectedImage, normalImage: unSelectedImage), title: "Anonymous", permission: .anonymous, isSelected: false))
        model.append(ListSelectionModel(image: RadioTypeImage(selectedImage: selectedImage, normalImage: unSelectedImage), title: "Hide result before voting", permission: .hideResultBeforeVoting, isSelected: true))
        let selectionView = ListSelectionView(models: model, title: "Show Result")
        return selectionView
    }()
    
    var question: String? {
        get {
            return self.askQuestionTextView.textView.textView.text
        }
    }
    
    let btnCancel: DyteButton = {
        let button = DyteButton(style: .text, size: .medium)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(DesignLibrary.shared.color.status.danger, for: .normal)
        return button
    }()
    
    let btnPublish: DyteButton = {
        let button = DyteButton(style: .solid, size: .medium)
        button.setTitle("  Publish  ", for: .normal)
        return button
    }()
    
    let baseView = UIView()
    
    init() {
        super.init(frame: .zero)
        self.addSubview(baseView)
        baseView.set(.fillSuperView(self, space.space4))
        createSubView(on: baseView)
        self.backgroundColor = backGroundColor
        self.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSubView(on view: UIView) {
        view.addSubview(lblHeader)
        view.addSubview(askQuestionTextView)
        view.addSubview(addOptionView)
        view.addSubview(permissionSelectionView)
        view.addSubview(btnCancel)
        view.addSubview(btnPublish)
        
        lblHeader.set(.sameLeadingTrailing(view),
                      .top(view))
        askQuestionTextView.set(.sameLeadingTrailing(view),
                                .below(lblHeader, verticalSpacingBetweenElemements))
        addOptionView.set(.sameLeadingTrailing(view),
                          .below(askQuestionTextView, verticalSpacingBetweenElemements))
        permissionSelectionView.set(.below(addOptionView, verticalSpacingBetweenElemements),
                          .sameLeadingTrailing(view))
        btnPublish.set(.bottom(view),
                       .trailing(view),
                       .below(permissionSelectionView, verticalSpacingBetweenElemements))
        btnCancel.set(.leading(view),
                       .centerY(btnPublish))
        
    }

}

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}

public class CreatePollsViewController: UIViewController, KeyboardObservable {
    let scrollView:UIScrollView = {return UIScrollView()}()
    var keyboardObserver: KeyboardObserver?
    let dyteMobileClient: DyteMobileClient
    let completion:(Result<Bool,Error>)->Void
    let tokenSpace = DesignLibrary.shared.space
    private var createPollView: CreatePollView!
    
    init(dyteMobileClient: DyteMobileClient, completion:@escaping(Result<Bool,Error>)->Void) {
        self.dyteMobileClient = dyteMobileClient
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.dyteMobileClient.addPollEventsListener(pollEventsListener: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    func setUpView() {
        createSubView(on: self.view)
        setupKeyboard()
    }
    
    private func createSubView(on view: UIView) {
        view.addSubview(scrollView)
        let createPollView = CreatePollView()
        createPollView.btnPublish.addTarget(self, action: #selector(publishButtonClick(button:)), for: .touchUpInside)
        createPollView.btnCancel.addTarget(self, action: #selector(cancelButtonClick(button:)), for: .touchUpInside)
        
        scrollView.addSubview(createPollView)
        createPollView.set(.fillSuperView(scrollView))
        scrollView.set(.leading(view, tokenSpace.space3),
                       .top(view, tokenSpace.space4),
                       .trailing(view, tokenSpace.space3),
                       .bottom(view),
                       .equateAttribute(.width, toView: createPollView, toAttribute: .width, withRelation: .equal))
        self.createPollView = createPollView
    }
                                            
    @objc func publishButtonClick(button : DyteButton) {
        let addOptionView = self.createPollView.addOptionView
        let allOptions = addOptionView.getAllOptions()
        if  let question = self.createPollView.question, question.count > 2 {
            self.createPollView.askQuestionTextView.lblError.isHidden = false
            if allOptions.count >= addOptionView.minimumOptionsToBeShown, let currentPermissionSelectedIndex = self.createPollView.permissionSelectionView.getCurrentSelectedIndex() {
                button.showActivityIndicator()

                var anonymous = false
                var hideVotes = false
                currentPermissionSelectedIndex.forEach { index in
                    let model = self.createPollView.permissionSelectionView.models[index]
                    if model.permission == .anonymous {
                        anonymous = true
                    }
                    else if model.permission == .hideResultBeforeVoting {
                        hideVotes = true
                    }
                }
                self.dyteMobileClient.polls.create(question: question, options: allOptions, anonymous: anonymous, hideVotes: hideVotes)

            }
        }else {
            self.createPollView.askQuestionTextView.lblError.isHidden = false
        }
        
    }
    
    @objc func cancelButtonClick(button : DyteButton) {
        self.dyteMobileClient.removePollEventsListener(pollEventsListener: self)
        self.completion(.success(false))
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { keyboardFrame in
            self.scrollView.get(.bottom)?.constant = -keyboardFrame.height
           // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {
            self.scrollView.get(.bottom)?.constant = 0

           // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
extension CreatePollsViewController: DytePollEventsListener {
    public func onNewPoll(poll: DytePollMessage) {
        self.dyteMobileClient.removePollEventsListener(pollEventsListener: self)
        self.completion(.success(true))
    }
    
    public func onPollUpdates(pollMessages: [DytePollMessage]) {
        
    }
}


    
