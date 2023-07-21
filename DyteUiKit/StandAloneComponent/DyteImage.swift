//
//  DyteImage.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit

public struct DyteImage {
    public  var image:UIImage?
    public var url: URL?
    public init(image: UIImage? = nil, url: URL? = nil) {
        self.image = image
        self.url = url
    }
    public var renderingMode: UIImage.RenderingMode = .alwaysOriginal
}
