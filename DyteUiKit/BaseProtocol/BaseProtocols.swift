//
//  BaseProtocols.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

protocol Searchable {
    func search(text: String) -> Bool
}


public protocol ReusableObject: AnyObject {}
extension ReusableObject {
  static var reuseIdentifier: String {
        return String(describing: self)
    }
}


protocol SetTopbar {
    var topBar: DyteNavigationBar {get}
}
extension SetTopbar where Self:UIViewController {
    func addTopBar(dismissAnimation: Bool, completion:(()->Void)? = nil) {
        topBar.setClicks { [weak self] button in
            guard let self = self else {return}
            if self.isModal {
                self.dismiss(animated: dismissAnimation, completion: completion)
            }else {
                self.navigationController?.popViewController(animated: dismissAnimation)
                completion?()
            }
        }
        self.view.addSubview(self.topBar)
        topBar.set(.sameLeadingTrailing(self.view),
                   .top(self.view),
                   .height(44))
    }
}


protocol KeyboardObservable: AnyObject {
    var keyboardObserver: KeyboardObserver? { get set }
    func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void)
    func stopKeyboardObserving()
}
extension KeyboardObservable {
    func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void) {
        keyboardObserver = KeyboardObserver(onShow: onShow, onHide: onHide)
    }
    
    
    func stopKeyboardObserving() {
        keyboardObserver?.stopObserving()
        keyboardObserver = nil
    }

}