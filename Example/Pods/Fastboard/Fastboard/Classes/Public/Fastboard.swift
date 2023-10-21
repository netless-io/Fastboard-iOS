//
//  Fastboard.swift
//  Fastboard
//
//  Created by xuyunshi on 2021/12/28.
//

import UIKit
import Whiteboard

let versionNumber = "1.3.0"

public class Fastboard: NSObject {
    /// Change this to update the whiteRoom ratio and whiteboardView ratio
    @objc
    public static var globalFastboardRatio: CGFloat = 16.0 / 9.0
    
    @objc
    /// Create a Fastboard with FastConfiguration
    /// - Parameter config: Configuration for fastboard
    public class func createFastRoom(withFastRoomConfig config: FastRoomConfiguration) -> FastRoom {
        return FastRoom(configuration: config)
    }
}
