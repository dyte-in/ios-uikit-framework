//
//  BaseAtom.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public class BaseView: UIView {
    
}

public class BaseStackView: UIStackView {
    
}

public class BaseAtomView:UIView, BaseAtom  {
    var isConstraintAdded: Bool = false    
}

public class BaseMoluculeView:UIView, Molecule  {
    var atoms: [BaseAtom] = [BaseAtom]()
    var isConstraintAdded: Bool = false
}

public class BaseImageView: UIImageView {
    func setImage(image: DyteImage?, completion:((UIImage)-> Void)? = nil) {
        if let image = image?.image {
            self.image = image.withRenderingMode(image.renderingMode)
            completion?(self.image ?? image)
        }else {
            if let url = image?.url {
              let result = ImageUtil.shared.obtainImageWithPath(url: url, completionHandler: { image, url in
                    self.image = image.withRenderingMode(image.renderingMode)
                   completion?(self.image ?? image)
               })
                if let image = result.0 {
                   self.image = image.withRenderingMode(image.renderingMode)
                   completion?(self.image ?? image)
               }
            }
        }
        
    }
}

protocol AutoLayoutable: UIView {
    var  isConstraintAdded:Bool {get}
    func createSubviews()
}

extension AutoLayoutable {
    
    func createSubviews() {
        
    }
}

protocol BaseAtom: AutoLayoutable{
        
}

protocol Molecule: AutoLayoutable {
    var atoms:[BaseAtom] {get}
}
