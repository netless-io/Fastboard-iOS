import Fastboard
import Whiteboard

class HTStrokeItem: FastRoomOperationItem {
    public init(width: CGFloat) {
        self.width = width
        identifier = width.description
        action = { room, _ in
            let state = WhiteMemberState()
            state.strokeWidth = .init(value: width)
            room.setMemberState(state)
        }
    }

    public func setEnable(_ enable: Bool) {
        button.isEnabled = enable
    }

    let width: CGFloat
    public var room: WhiteRoom?
    var interrupter: ((FastRoomOperationItem) -> Void)?
    public var identifier: String?
    public var associatedView: UIView? { button }
    public var action: (WhiteRoom, Any?) -> Void

    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        let colorWidth: CGFloat = width
        let img = UIImage.colorItemImage(withColor: .gray,
                               size: .init(width: colorWidth, height: colorWidth),
                               radius: colorWidth / 2)
        btn.setImage(img, for: .normal)
        let selImg = UIImage.colorItemImage(withColor: .cyan,
                               size: .init(width: colorWidth, height: colorWidth),
                               radius: colorWidth / 2)
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
