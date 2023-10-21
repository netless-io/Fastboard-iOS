//
//  HTExecutionItem.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Fastboard
import Whiteboard

class HTExecutionItem: FastRoomOperationItem {
    init(image: UIImage,
         disableImage: UIImage? = nil,
         title: String,
         action: @escaping ((WhiteRoom, Any?) -> Void),
         identifier: String?)
    {
        self.action = action
        self.identifier = identifier

        let btn = UIButton(type: .custom)
        btn.setImage(image, for: .normal)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: htItemSystemFontSize)
        btn.setTitleColor(htItemTitleColor, for: .normal)
        btn.tintColor = htItemTintColor
        if let disableImage {
            btn.setImage(disableImage, for: .disabled)
        }
        btn.verticalCenterImageAndTitleWith(htItemVerticalSpaceing)
        button = btn
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }

    var button: UIButton
    var action: (WhiteRoom, Any?) -> Void
    var room: WhiteRoom?
    var associatedView: UIView? { button }
    var identifier: String?
    var interrupter: ((FastRoomOperationItem) -> Void)? = nil

    func buildView(interrupter: ((FastRoomOperationItem) -> Void)?) -> UIView {
        self.interrupter = interrupter
        return button
    }

    func setEnable(_ enable: Bool) {
        button.isEnabled = enable
    }

    @objc func onClick(sender: Any?) {
        guard let room = room else { return }
        interrupter?(self)
        action(room, sender)
    }
}
