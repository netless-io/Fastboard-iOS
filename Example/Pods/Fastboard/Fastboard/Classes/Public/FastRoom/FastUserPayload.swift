//
//  FastUserPayload.swift
//  Fastboard
//
//  Created by xuyunshi on 2022/11/23.
//

import Foundation


/// Represents the user info display no whiteboard cursor
@objc
public class FastUserPayload: NSObject {
    let nickName: String?
    let avatar: String?
    
    var dic: [String: String] {
        var r = [String: String]()
        if let nickName = nickName { r["nickName"] = nickName }
        if let avatar = avatar { r["avatar"] = avatar }
        return r
    }
    
    /// Create cursor user info with nickname
    public init(nickName: String) {
        self.nickName = nickName
        self.avatar = nil
        super.init()
    }
    
    /// Create cursor user info with nickname and avatar
    public init(nickName: String, avatar: String) {
        self.nickName = nickName
        self.avatar = avatar
        super.init()
    }
}
