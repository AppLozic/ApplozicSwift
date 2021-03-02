//
//  UIImage+Scale.swift
//  Applozic
//
//  Created by Sunil on 22/05/20.
//

import Foundation
import UIKit

public extension UIImage {
    // Scale a UIImage to any given rect keeping the aspect ratio
    // https://gist.github.com/tomasbasham/10533743#gistcomment-2865851
    func scale(with size: CGSize) -> UIImage? {
        var scaledImageRect = CGRect.zero

        let aspectWidth: CGFloat = size.width / self.size.width
        let aspectHeight: CGFloat = size.height / self.size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)

        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        draw(in: scaledImageRect)

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
}
