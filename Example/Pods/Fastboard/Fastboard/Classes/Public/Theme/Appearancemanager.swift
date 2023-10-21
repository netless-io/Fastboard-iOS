//
//  AppearanceManager.swift
//  Fastboard
//
//  Created by xuyunshi on 2022/1/6.
//

import Foundation

public class AppearanceManager: NSObject {
    @objc
    public static let shared = AppearanceManager()
    private override init() {}
    
    func keyWindow() -> UIWindow? {
        if #available(iOS 13, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let scene = scene as? UIWindowScene {
                    if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                        return keyWindow
                    }
                }
            }
        } else {
            return UIApplication.shared.keyWindow
        }
        return nil
    }
    
    @objc
    public func commitUpdate() {
        let window = keyWindow()
        window?.subviews.forEach {
            $0.removeFromSuperview()
            window?.addSubview($0)
        }
    }
}
