//
//  HTApplianceItem.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Fastboard
import Whiteboard

class HTApplianceItem: FastRoomOperationItem {
    init(image: UIImage,
                  selectedImage: UIImage?,
                  title: String,
                  action: @escaping ((WhiteRoom, Any?) -> Void),
                  identifier: String?)
    {
        self.action = action
        self.identifier = identifier

        let btn = UIButton(type: .custom)
        btn.setImage(image, for: .normal)
        btn.setImage(selectedImage, for: .selected)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: htItemSystemFontSize)
        btn.setTitleColor(htItemTitleColor, for: .normal)
        btn.tintColor = htItemTintColor
        btn.verticalCenterImageAndTitleWith(htItemVerticalSpaceing)
        button = btn
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }

    var button: UIButton
    var action: (WhiteRoom, Any?) -> Void
    var identifier: String?
    var interrupter: ((FastRoomOperationItem) -> Void)? = nil
    weak var associatedView: UIView? { button }
    weak var room: WhiteRoom? = nil

    func buildView(interrupter: ((FastRoomOperationItem) -> Void)?) -> UIView {
        self.interrupter = interrupter
        return button
    }

    func setEnable(_ enable: Bool) {
        button.isEnabled = enable
    }

    @objc
    func onClick(_ sender: UIButton) {
        guard let room = room else { return }
        interrupter?(self)
        action(room, nil)
        sender.isSelected = true
    }
}
