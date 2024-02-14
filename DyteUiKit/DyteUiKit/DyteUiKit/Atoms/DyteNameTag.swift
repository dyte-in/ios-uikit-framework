//
//  DyteNameTag.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit
import DyteiOSCore


public protocol BaseAppearance {
    var desingLibrary: DyteDesignTokens {get}
    init(designLibrary: DyteDesignTokens)
}

public protocol DyteNameTagAppearance: BaseAppearance {
    var backGroundColor: BackgroundColorToken.Shade {get set}
    var titleFont: UIFont {get set}
    var titleTextColorToken: TextColorToken.Background.Shade {get set}
    var subTitleFont: UIFont {get set}
    var subTitleTextColorToken: TextColorToken.Background.Shade? {get set}
    var cornerRadius: BorderRadiusToken.RadiusType {get set}
    var paddings: UIEdgeInsets{get set}
}

public class DyteNameTagAppearanceModel: DyteNameTagAppearance {
    public var backGroundColor: BackgroundColorToken.Shade
    public var titleTextColorToken: TextColorToken.Background.Shade
    public var subTitleTextColorToken: TextColorToken.Background.Shade?
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var titleFont: UIFont
    public var subTitleFont: UIFont
    public var paddings: UIEdgeInsets
    public var desingLibrary: DyteDesignTokens
    
    required public init(designLibrary: DyteDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        paddings = UIEdgeInsets(top: designLibrary.space.space1,
                                left: designLibrary.space.space1,
                                bottom: designLibrary.space.space1,
                                right: designLibrary.space.space1)
        backGroundColor = designLibrary.color.background.shade900
        titleTextColorToken = designLibrary.color.textColor.onBackground.shade1000
        subTitleTextColorToken = designLibrary.color.textColor.onBackground.shade600
        titleFont = UIFont.systemFont(ofSize: 16)
        subTitleFont = UIFont.systemFont(ofSize: 12)
    }
}

public class DyteNameTag : BaseAtomView {
    
    private enum Placement {
        case left
        case right
    }
    
    private let baseStackView: BaseStackView = {
        let stackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: 4.0)
        stackView.alignment = .center
        return stackView
    }()
    
    public var lblTitle: DyteText = {
        let lbl = DyteUIUTility.createLabel(text: "", alignment: .left)
        lbl.minimumScaleFactor = 0.8
        return lbl
    }()
    
    public var lblSubTitle: DyteText?
    
    public var imageView: BaseImageView = {
        let imageView = BaseImageView()
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateImageViewConstraints()
    }
    
    private func updateImageViewConstraints() {
        let imageheightLeft: CGFloat = self.frame.height - (appearance.paddings.top + appearance.paddings.bottom)
        let originalHeight: CGFloat = appearance.paddings.top + appearance.paddings.bottom + self.imageView.intrinsicContentSize.height
        let imageViewNaturalHeight = imageView.intrinsicContentSize.height
        var newHeight = imageViewNaturalHeight

        if imageheightLeft < imageViewNaturalHeight {
            //New height is less than the original height required
            newHeight = (imageViewNaturalHeight/originalHeight)*imageheightLeft
        }
        
        if imageView.get(.width) == nil {
            imageView.set(.width(newHeight))
        }
        if imageView.get(.height) == nil {
            imageView.set(.height(newHeight))
        }
        imageView.get(.width)?.constant = newHeight
        imageView.get(.height)?.constant = newHeight

       
    }
    
    private var lableStackView: BaseStackView = {
        let stackView = DyteUIUTility.createStackView(axis: .vertical,distribution: .fillEqually, spacing: 4.0)
        return stackView
    }()
    
    private let image: DyteImage
    private let titleText: String
    private let subtitle: String
    var appearance: DyteNameTagAppearance
    
    public init(image:DyteImage, appearance: DyteNameTagAppearance = DyteNameTagAppearanceModel(), title: String, subtitle: String = "") {
        self.image = image
        self.appearance = appearance
        self.titleText = title
        self.subtitle = subtitle
        super.init(frame: .zero)
        createSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DyteNameTag {
    func setTitle(text: String?) {
        self.lblTitle.text = text
    }
    
    func getTitle() -> String? {
        return self.lblTitle.text
    }
    
    func setSubTitle(text: String?) {
        self.lblSubTitle?.text = text
    }
}

extension DyteNameTag {
    
    private func createSubViews() {
        self.addSubview(baseStackView)
        let wrappedImageView = imageView.wrapperView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.set(.fillSuperView(wrappedImageView))
        baseStackView.addArrangedSubview(wrappedImageView)
        baseStackView.addArrangedSubview(lableStackView)
        lableStackView.addArrangedSubview(lblTitle)
        lblTitle.text = titleText
        imageView.image = image.image
        if self.subtitle.isEmpty == false  {
            lblSubTitle = DyteUIUTility.createLabel(text: subtitle)
            lblSubTitle?.adjustsFontSizeToFitWidth = true
            lableStackView.addArrangedSubview(lblSubTitle!)
        }
        addConstraints()
        applyDesign(appearance: appearance)
    }
    
    public func applyDesign(appearance: DyteNameTagAppearance) {
        self.appearance = appearance
        self.backgroundColor = appearance.backGroundColor
        self.layer.cornerRadius = appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: appearance.cornerRadius)
        self.lblTitle.textColor = appearance.titleTextColorToken
        self.lblSubTitle?.textColor = appearance.subTitleTextColorToken
    }
    
    private func addConstraints() {    
        baseStackView.set(.leading(self, appearance.paddings.left),
                          .trailing(self, appearance.paddings.right),
                          .top(self, appearance.paddings.top,.lessThanOrEqual),
                          .bottom(self, appearance.paddings.left,.lessThanOrEqual))
    }
}

