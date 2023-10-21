import Fastboard
import Whiteboard

class HTColorItem: FastRoomOperationItem {
    public init(color: UIColor) {
        self.color = color
        identifier = color.description
        action = { _, _ in }
        action = { [weak self] room, _ in
            guard let self = self else { return }
            let state = WhiteMemberState()
            state.strokeColor = self.color.getNumbersArray()
            room.setMemberState(state)
        }
    }

    public func setEnable(_ enable: Bool) {
        button.isEnabled = enable
    }

    let color: UIColor
    public var room: WhiteRoom?
    var interrupter: ((FastRoomOperationItem) -> Void)?
    public var identifier: String?
    public var associatedView: UIView? { button }
    public var action: (WhiteRoom, Any?) -> Void

    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        let colorWidth: CGFloat = 20
        let img = UIImage.selectedColorItemImage(withColor: color,
                                                 size: .init(width: colorWidth, height: colorWidth),
                                                 radius: colorWidth / 2,
                                                 borderColor: .white)
        btn.setImage(img, for: .normal)
        let selImg = UIImage.selectedColorItemImage(withColor: color,
                                                    size: .init(width: colorWidth, height: colorWidth),
                                                    radius: colorWidth / 2,
                                                    borderColor: .white,
                                                    checkMark: true)
        btn.setImage(selImg, for: .selected)
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return btn
    }()

    @objc func onClick() {
        guard let room = room else { return }
        interrupter?(self)
        button.isSelected = true
        action(room, nil)
    }

    public func buildView(interrupter: ((FastRoomOperationItem) -> Void)?) -> UIView {
        self.interrupter = interrupter
        return button
    }
}
