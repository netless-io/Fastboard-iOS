import Whiteboard
import Fastboard

extension UIImage {
    static func colorItemImage(withColor color: UIColor,
                               size: CGSize,
                               radius: CGFloat) -> UIImage? {
        let lineColor: CGColor = UIColor.black.withAlphaComponent(0.24).cgColor
        let lineWidth: CGFloat = 0 // 1
        let radius: CGFloat = radius
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let current = UIGraphicsGetCurrentContext()
        current?.setFillColor(color.cgColor)
        let pointRect = CGRect.init(origin: .zero, size: size)
        let bezeier = UIBezierPath(roundedRect: pointRect, cornerRadius: radius)
        current?.addPath(bezeier.cgPath)
        current?.fillPath()
        
        let strokeBezier = UIBezierPath(roundedRect: pointRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2), cornerRadius: radius)
        current?.beginPath()
        current?.addPath(strokeBezier.cgPath)
        current?.setLineWidth(lineWidth)
        current?.setStrokeColor(lineColor)
        current?.strokePath()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func selectedColorItemImage(withColor color: UIColor,
                               size: CGSize,
                               radius: CGFloat,
                               borderColor: UIColor,
                                       checkMark: Bool = false) -> UIImage? {
        let selectedExpandMargin: CGFloat = 3
        let canvasSize = CGSize(width: size.width + selectedExpandMargin * 2, height: size.height + selectedExpandMargin * 2)
        
        let lineColor: CGColor = UIColor.black.withAlphaComponent(0.24).cgColor
        let lineWidth: CGFloat = 0 // 1
        let radius: CGFloat = radius
        
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, UIScreen.main.scale)
        let current = UIGraphicsGetCurrentContext()
        
        let selectedLineWidth = CGFloat(3)
        let selectedRect = CGRect(origin: .zero, size: canvasSize)
        let selectedLinePath = UIBezierPath(roundedRect: selectedRect.insetBy(dx: selectedLineWidth, dy: selectedLineWidth), cornerRadius: radius)
        current?.beginPath()
        current?.addPath(selectedLinePath.cgPath)
        current?.setLineWidth(selectedLineWidth)
        current?.setStrokeColor(borderColor.cgColor)
        current?.strokePath()
        
        current?.setFillColor(color.cgColor)
        let pointRect = CGRect.init(origin: .init(x: selectedExpandMargin, y: selectedExpandMargin), size: size)
        let bezier = UIBezierPath(roundedRect: pointRect, cornerRadius: radius)
        current?.addPath(bezier.cgPath)
        current?.fillPath()
        
        let strokeBezier = UIBezierPath(roundedRect: pointRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2), cornerRadius: radius)
        current?.beginPath()
        current?.addPath(strokeBezier.cgPath)
        current?.setLineWidth(lineWidth)
        current?.setStrokeColor(lineColor)
        current?.strokePath()
        
        if checkMark {
            let checkMarkPath = UIBezierPath()
            checkMarkPath.move(to: .init(x: canvasSize.width / 3, y: canvasSize.height / 2))
            checkMarkPath.addLine(to: .init(x: canvasSize.width / 2, y: canvasSize.height / 3 * 2))
            checkMarkPath.addLine(to: .init(x: canvasSize.width / 3 * 2, y: canvasSize.height / 3))
            checkMarkPath.addLine(to: .init(x: canvasSize.width / 2, y: canvasSize.height / 3 * 2))
            checkMarkPath.close()
            borderColor.setStroke()
            checkMarkPath.lineWidth = 2
            checkMarkPath.stroke()
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class HTPencilItem: FastRoomOperationItem {
    var action: ((WhiteRoom, Any?) -> Void) = {_,_ in }
    var room: WhiteRoom?
    var associatedView: UIView? = nil
    var interrupter: ((FastRoomOperationItem) -> Void)? = nil
    var identifier: String? = nil // TODO
    var subOps: [FastRoomOperationItem] = [
        FastRoomDefaultOperationItem.selectableApplianceItem(.AppliancePencil),
        FastRoomDefaultOperationItem.selectableApplianceItem(.ApplianceStraight),
        FastRoomDefaultOperationItem.selectableApplianceItem(.ApplianceRectangle),
        FastRoomDefaultOperationItem.selectableApplianceItem(.ApplianceEllipse),
        
        HTStrokeItem(width: 6),
        HTStrokeItem(width: 8),
        HTStrokeItem(width: 12),
        HTStrokeItem(width: 16),
        
        HTColorItem(color: .red),
        HTColorItem(color: .orange),
        HTColorItem(color: .yellow),
        HTColorItem(color: .green),
        HTColorItem(color: .cyan),
        HTColorItem(color: .blue),
        HTColorItem(color: .systemPink),
        HTColorItem(color: .purple),
        HTColorItem(color: .lightGray),
        HTColorItem(color: .gray),
        HTColorItem(color: .darkGray),
        HTColorItem(color: .black),
    ]
    var selectedApplianceItem: ApplianceItem? {
        didSet {
            updateSelectedApplianceItem()
        }
    }
    var selectedColorItem: HTColorItem? {
        didSet {
            updateSelectedColorItem()
        }
    }
    var selectedStrokeItem: HTStrokeItem? {
        didSet {
            updateSelectedStrokeWidth()
        }
    }
    
    func updateSelectedApplianceItem() {
        deselectAllApplianceItems()
        if let selectedApplianceItem = selectedApplianceItem {
            (selectedApplianceItem.associatedView as? UIButton)?.isSelected = true
            (associatedView as? UIButton)?.isSelected = true
        }
    }
    
    func updateSelectedColorAsset() {
        return
    }
    
    func deselectAllApplianceItems() {
        subOps
            .compactMap { $0 as? ApplianceItem }
            .compactMap { $0.associatedView as? UIButton }
            .forEach { $0.isSelected = false }
    }
    
    func deselectAllColorItems() {
        subOps
            .compactMap { $0 as? HTColorItem }
            .map { $0.button }
            .forEach { $0.isSelected = false }
    }
    
    func deselectAllStrokeItems() {
        subOps
            .compactMap { $0 as? HTStrokeItem }
            .map { $0.button }
            .forEach { $0.isSelected = false }
    }
    
    func updateSelectedStrokeWidth() {
        deselectAllStrokeItems()
        (selectedStrokeItem?.associatedView as? UIButton)?.isSelected = true
    }
    
    func updateSelectedColorItem() {
        updateSelectedColorAsset()
        deselectAllColorItems()
        (selectedColorItem?.associatedView as? UIButton)?.isSelected = true
    }
    
    lazy var subPanelView: HTSubPanelView = {
        let view = HTSubPanelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func setupSubPanelViewHierarchy() {
        func loopForFastboardView(from: UIView) -> FastRoomView? {
            var current: UIView? = from
            while current != nil {
                current = current?.superview
                if let current = current as? FastRoomView {
                    return current
                }
            }
            return nil
        }
        
        if subPanelView.superview == nil {
            let container = loopForFastboardView(from: associatedView!)
            if let whiteboardView = container!.whiteboardView {
                container?.insertSubview(subPanelView, aboveSubview: whiteboardView)
            } else {
                container?.addSubview(subPanelView)
            }
        }
    }
    
    @objc
    func onClick() {
        guard let room = room else { return }
        interrupter?(self)
        selectedApplianceItem?.action(room, nil)

        // Update self UI
        if let _ = selectedApplianceItem {
            updateSelectedApplianceItem()
        }
        if let _ = selectedColorItem {
            updateSelectedColorItem()
        }
        if let _ = selectedStrokeItem {
            updateSelectedStrokeWidth()
        }
        (associatedView as? UIButton)?.isSelected = true
        
        if subPanelView.superview == nil {
            setupSubPanelViewHierarchy()
            subPanelView.show()
        } else {
            if subPanelView.isHidden {
                subPanelView.show()
            }
        }
    }
    
    func subItemExecuted(subItem: FastRoomOperationItem) {
        interrupter?(subItem)
        // Update current button image on panel
        if let item = subItem as? ApplianceItem {
            selectedApplianceItem = item
        }
        if let item = subItem as? HTColorItem {
            selectedColorItem = item
        }
        if let item = subItem as? HTStrokeItem {
            selectedStrokeItem = item
        }
    }
    
    func buildView(interrupter: ((FastRoomOperationItem) -> Void)?) -> UIView {
        identifier = subOps.compactMap(\.identifier).joined(separator: "-")
        selectedApplianceItem = subOps.compactMap { $0 as? ApplianceItem }.first
        
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ht-pencil"), for: .normal)
        btn.setImage(UIImage(named: "ht-pencil-selected"), for: .selected)
        btn.setTitle("画笔", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: htItemSystemFontSize)
        btn.setTitleColor(htItemTitleColor, for: .normal)
        btn.tintColor = htItemTintColor
        btn.verticalCenterImageAndTitleWith(htItemVerticalSpaceing)
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.interrupter = interrupter
        self.associatedView = btn
        
        let ops = subOps
        ops.forEach {
            $0.room = room
            _ = $0.buildView { [weak self] item in
                self?.subItemExecuted(subItem: item)
            }
        }
        
        let showedSubOpsView = ops.map { $0.associatedView! }
        self.subPanelView.setupFromItemViews(views: showedSubOpsView)
        self.subPanelView.exceptView = associatedView
        return btn
    }
    
    func setEnable(_ enable: Bool) {}
}
