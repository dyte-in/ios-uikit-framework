//
//  ReusableTableViewCell.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/02/23.
//

import UIKit



class TitleTableViewCell: BaseTableViewCell {
    let lblTitle = {
        let lblTitle = UIUTility.createLabel()
        return lblTitle
    }()
    
    private var viewModel: TitleTableViewCellModel?
    
    func createSubView(on baseView: UIView) {
        baseView.addSubview(lblTitle)
        lblTitle.set(.fillSuperView(baseView))
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    func setupView() {
        let baseView = UIView()
        createSubView(on: baseView)
        contentView.addSubview(baseView)
        baseView.set(.below(self.cellSeparatorTop, tokenSpace.space5),
                     .above(cellSeparatorBottom, tokenSpace.space5),
                     .sameLeadingTrailing(contentView,tokenSpace.space4))
      
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
struct TitleTableViewCellModel {
    var title: String
}

extension TitleTableViewCell: ConfigureView {
    var model: TitleTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: TitleTableViewCellModel) {
        viewModel = model
        self.lblTitle.text = model.title
    }
}

class AcceptButtonTableViewCell: ButtonTableViewCell {
    
    override func setupView() {
        super.setupView()
        self.button.backgroundColor = tokenColor.background.shade800
    }
}

class RejectButtonTableViewCell: ButtonTableViewCell {
    
    override func setupView() {
        super.setupView()
        self.button.backgroundColor = tokenColor.background.shade800
    }
}


class ButtonTableViewCell: BaseTableViewCell {
    
    let button = {
        let button = DyteButton()
        return button
    }()
    
    var buttonClick:((DyteButton) -> Void)?
    private var viewModel: ButtonTableViewCellModel?

    func createSubView(on baseView: UIView) {
        baseView.addSubview(button)
        button.set(.fillSuperView(baseView))
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    func setupView() {
        let baseView = UIView()
        createSubView(on: baseView)
        contentView.addSubview(baseView)
        baseView.set(.below(self.cellSeparatorTop, tokenSpace.space2),
                     .above(cellSeparatorBottom, tokenSpace.space2),
                     .sameLeadingTrailing(cellSeparatorBottom))
        button.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
    }
    
   @objc func buttonClick(button: DyteButton) {
       self.buttonClick?(button)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ButtonTableViewCellModel {
    var buttonTitle: String
    var titleColor: UIColor = tokenColor.status.success
}

extension ButtonTableViewCell: ConfigureView {
    var model: ButtonTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: ButtonTableViewCellModel) {
        viewModel = model
        self.button.setTitle(model.buttonTitle, for: .normal)
        self.button.setTitleColor(model.titleColor, for: .normal)
    }
}


struct SearchTableViewCellModel {
    var placeHolder: String
}

class SearchTableViewCell: BaseTableViewCell {
    let searchBar = {
        let searchBar = UISearchBar()
        searchBar.changeText(color: tokenColor.textColor.onBackground.shade700)
        searchBar.searchBarStyle = .minimal
        searchBar.isUserInteractionEnabled = false
        return searchBar
    }()
    private var viewModel: SearchTableViewCellModel?

    
    func createSubView(on baseView: UIView) {
        baseView.addSubview(searchBar)
        searchBar.set(.fillSuperView(baseView))
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    func setupView() {
        let baseView = UIView()
        createSubView(on: baseView)
        contentView.addSubview(baseView)
        baseView.set(.below(self.cellSeparatorTop, tokenSpace.space2),
                     .above(cellSeparatorBottom, tokenSpace.space2),
                     .sameLeadingTrailing(contentView,tokenSpace.space4))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension SearchTableViewCell: ConfigureView {
    var model: SearchTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: SearchTableViewCellModel) {
        viewModel = model
        self.searchBar.placeholder = model.placeHolder
    }
}
