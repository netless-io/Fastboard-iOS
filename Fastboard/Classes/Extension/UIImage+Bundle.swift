//
//  UIImage+Bundle.swift
//  Fastboard
//
//  Created by xuyunshi on 2021/12/30.
//

import UIKit

let defaultBundle: Bundle = {
    if let path = Bundle(for: Fastboard.self).path(forResource: "Fastboard_Fastboard", ofType: "bundle") {
        return Bundle(path: path)!
    } else if let path = Bundle(for: Fastboard.self).path(forResource: "Icons", ofType: "bundle") {
        return Bundle(path: path)!
    }
    return Bundle.main
}()

var iconsBundle: Bundle = defaultBundle

extension UIImage {
    static func currentBundle(named: String) -> UIImage? {
        if let img = UIImage(named: named, in: iconsBundle, compatibleWith: nil) {
            return img
        }
        return UIImage(named: named, in: defaultBundle, compatibleWith: nil)
    }
}
