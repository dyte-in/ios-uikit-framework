//
//  ImageProvider.swift
//  DyteUiKit
//
//  Created by sudhir kumar on 30/11/22.
//

import UIKit

public class ImageProvider {
    // for any image located in bundle where this class has built
    public static func image(named: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            let bundle = Bundle(for: BaseView.self)
            let image = UIImage(named: named, in: bundle, with: nil)
            print(")))))))))))) Bundle \(bundle) \(image)")
            return image
        } else {
            // Fallback on earlier versions
            let frameworkBundle =  Bundle(for: ImageProvider.self)
            let imagePath = frameworkBundle.path(forResource: named, ofType: "png")
            return  UIImage(contentsOfFile: imagePath!)
        }
    }
}

public class FileDownloader {
    static func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let session = URLSession(configuration: .default)

        let downloadTask = session.downloadTask(with: url) { (location, response, error) in
            guard let location = location else {
                completion(false, error)
                return
            }

            do {
                try FileManager.default.moveItem(at: location, to: destinationURL)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }

        downloadTask.resume()
    }

}

final class ImageUtil {

    var task: URLSessionDownloadTask!
    var session = URLSession(configuration: .default)
    var cache: NSCache<NSString, UIImage>!
    static let shared = ImageUtil()
    private init(){
        session = URLSession.shared
        self.cache = NSCache()
    }
    func obtainImageWithPath(url: URL, completionHandler: @escaping (UIImage) -> Void)-> UIImage? {
       return self.obtainImageWithPath(imagePath: url.absoluteString, completionHandler: completionHandler)
    }
    func obtainImageWithPath(imagePath: String, completionHandler: @escaping(UIImage) -> Void) -> UIImage? {
        if let image = self.cache.object(forKey: imagePath as NSString) {
            return image
        } else {
            guard let placeholder = ImageProvider.image(named: "icon_image") else { return nil }
            if let url = URL(string: imagePath) {
                task = session.downloadTask(with: url, completionHandler: { (location, response, error) in
                    if let data = try? Data(contentsOf: url) {
                        if let img = UIImage(data: data) {
                            self.cache.setObject(img, forKey: imagePath as NSString)
                            DispatchQueue.main.async {
                                completionHandler(img)
                            }
                        } else {
                            print(Constants.errorLoadingImage)
                        }
                    }
                })
                task.resume()
                return placeholder
            }
            print(Constants.errorLoadingImage)
             return nil
        }
    }
}
