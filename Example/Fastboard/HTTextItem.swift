import Fastboard
import Whiteboard

class HTTextItem: FastRoomOperationItem {
    init(tap: @escaping (()->Void)) {
        self.action = { room, _ in
            let m = WhiteMemberState()
            m.currentApplianceName = .ApplianceSelector
            room.setMemberState(m)
            tap()
        }
        self.identifier = "===t=s==="
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ht_text"), for: .normal)
        btn.setTitle("文本", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: htItemSystemFontSize)
        btn.setTitleColor(htItemTitleColor, for: .normal)
        btn.tintColor = htItemTintColor
        btn.verticalCenterImageAndTitleWith(htItemVerticalSpaceing)
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.associatedView = btn
    }

    var action: (WhiteRoom, Any?) -> Void
    var identifier: String?
    var interrupter: ((FastRoomOperationItem) -> Void)? = nil
    var associatedView: UIView?
    weak var room: WhiteRoom? = nil

    func buildView(interrupter: ((FastRoomOperationItem) -> Void)?) -> UIView {
        self.interrupter = interrupter
        return associatedView!
    }

    func setEnable(_ enable: Bool) {
        (associatedView as? UIButton)?.isEnabled = enable
    }

    @objc
    func onClick(_ sender: UIButton) {
        guard let room = room else { return }
        interrupter?(self)
        action(room, nil)
        sender.isSelected = true
    }
}
