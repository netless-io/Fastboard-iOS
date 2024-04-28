//
//  Fastboard.swift
//  Fastboard
//
//  Created by xuyunshi on 2021/12/28.
//

import UIKit
import Whiteboard

let versionNumber = "1.4.2"

public class Fastboard: NSObject {
    /// Change this to update the whiteRoom ratio and whiteboardView ratio
    @objc
    public static var globalFastboardRatio: CGFloat = 16.0 / 9.0
    
    @objc
    /// Create a Fastboard with FastConfiguration
    /// - Parameter config: Configuration for fastboard
    public class func createFastRoom(withFastRoomConfig config: FastRoomConfiguration) -> FastRoom {
        let _ = FastRoomThemeManager.shared
        return FastRoom(configuration: config)
    }
}
