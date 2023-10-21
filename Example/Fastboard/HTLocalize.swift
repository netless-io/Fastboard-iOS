//
//  HTLocalize.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Whiteboard

extension WhiteApplianceNameKey {
    var localizedTitle: String {
        switch self {
        case .ApplianceHand: return "拖拽"
        case .ApplianceLaserPointer: return "激光笔"
        case .AppliancePencil: return "画笔"
        case .ApplianceText: return "文本"
        default: return rawValue
        }
    }
}
