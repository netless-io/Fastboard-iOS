//
//  TraitCollection+Extension.swift
//  Fastboard
//
//  Created by xuyunshi on 2022/1/4.
//

import UIKit

extension UITraitCollection {
    var hasCompact: Bool {
        verticalSizeClass == .compact || horizontalSizeClass == .compact
    }
}
