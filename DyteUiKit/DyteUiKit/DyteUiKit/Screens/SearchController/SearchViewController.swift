//
//  SearchViewController.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/02/23.
//

import UIKit

class SearchViewControllerModel {
    
    var dataSourceTableView: DataSourceSearchStandard<BaseConfiguratorSection<CollectionTableSearchConfigurator>>!

    func initialise(sections:[BaseConfiguratorSection<CollectionTableSearchConfigurator>], completion: ()->Void) {
        dataSourceTableView = DataSourceSearchStandard(sections: sections)
        completion()
    }
    
    func getMockSection() -> [BaseConfiguratorSection<CollectionTableSearchConfigurator>] {
        let sectionTwo =  BaseConfiguratorSection<CollectionTableSearchConfigurator>()
        
        return [sectionTwo]
    }
    
    func search(text: String, completion: ()->Void) {
        if text.isEmpty == true {
            self.dataSourceTableView.set(sections: self.dataSourceTableView.originalSections)
        }else {
            var sections =  [BaseConfiguratorSection<CollectionTableSearchConfigurator>]()
            for section in self.dataSourceTableView.originalSections {
                let filterSection =  BaseConfiguratorSection<CollectionTableSearchConfigurator>()
                for item in section.items {
                    if item.search(text: text) == true {
                        filterSection.insert(item)
                    }
                }
                if filterSection.items.count > 0 {
                    sections.append(filterSection)
                }
            }
            self.dataSourceTableView.set(sections: sections)
            completion()
        }
    }
}


public class SearchViewController: UIViewController, KeyboardObservable {
    
    let tableView = UITableView()
    let viewModel = SearchViewControllerModel()
    var keyboardObserver: KeyboardObserver?
    
    let searchBar = {
        let searchBar = UISearchBar()
        searchBar.changeText(color: dyteSharedTokenColor.textColor.onBackground.shade700)
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpView()
        setupKeyboard()
        searchBar.becomeFirstResponder()
    }
     
    func setUpView() {
        searchBar.delegate = self
        self.view.backgroundColor = dyteSharedTokenColor.background.shade1000
        self.view.addSubview(searchBar)
        searchBar.set(.top(self.view),
                      .sameLeadingTrailing(self.view))
        setUpTableView()
        self.viewModel.initialise(sections: self.viewModel.getMockSection()) {
            self.tableView.reloadData()
        }
    }

    func setUpTableView() {
        self.view.addSubview(tableView)
        tableView.backgroundColor = dyteSharedTokenColor.background.shade1000
        tableView.set(.sameLeadingTrailing(self.view),
                      .below(self.searchBar),
                      .bottom(self.view))
        registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    func registerCells(tableView: UITableView) {
        tableView.register(ParticipantInCallTableViewCell.self)
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { keyboardFrame in
            self.tableView.get(.bottom)?.constant = -keyboardFrame.height
           // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {
            self.tableView.get(.bottom)?.constant = 0
           // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
}


extension SearchViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.search(text: searchText) {
            self.tableView.reloadData()
        }
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.removeFromSuperview()
    }
}

extension SearchViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dataSourceTableView.numberOfSections()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSourceTableView.numberOfRows(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  self.viewModel.dataSourceTableView.configureCell(tableView: tableView, indexPath: indexPath)
        cell.backgroundColor = tableView.backgroundColor
        return cell
    }
    
}
