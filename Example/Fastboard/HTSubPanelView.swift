import UIKit

class HTSubPanelContainer: UIView {}

class HTSubPanelView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden else { return nil }
        var inside = self.point(inside: point, with: event)
        if let exceptView = exceptView {
            let p = convert(point, to: exceptView)
            if exceptView.point(inside: p, with: nil) {
                inside = true
            }
        }
        if !inside {
            hide()
        }
        return super.hitTest(point, with: event)
    }
    
    func hide() {
        if let _ = layer.animation(forKey: "show") {
            layer.removeAnimation(forKey: "show")
        }
        isHidden = true
    }
    
    func show() {
//        guard FastRoomPanel.enablePanelAnimation else {
//            isHidden = false
//            return
//        }
        setNeedsLayout()
        layoutIfNeeded()
        // Spring Animation
        let targetFrame = frame
        let offset: CGFloat
        if targetFrame.maxX > UIScreen.main.bounds.width / 2 {
            offset = (exceptView?.frame.size.width)!
        } else {
            offset = -(exceptView?.frame.size.width)!
        }
        
        let transAnimation = CASpringAnimation(keyPath: "transform.translation.x")
        transAnimation.fromValue = offset
        transAnimation.toValue = 0
        transAnimation.damping = 100
        transAnimation.stiffness = 1000
        transAnimation.initialVelocity = 0
        transAnimation.isRemovedOnCompletion = false
        transAnimation.fillMode = kCAFillModeForwards
        transAnimation.delegate = self
        layer.add(transAnimation, forKey: "show")
    }
    
    var animationOffset: CGFloat = 0
    weak var exceptView: UIView?
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.25
        layer.shadowOffset = .init(width: 0, height: 2.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds.insetBy(dx: shadowMargin, dy: shadowMargin)
        
        let s = containerView.subviews[4].frame
        let e = containerView.subviews[7].frame
        
        line.frame = .init(x: s.minX, y: s.maxY, width: e.maxX - s.minX, height: 0.5)
        
        guard let window = superview else { return }
        if let exceptView = exceptView {
            let ef = exceptView.superview!.convert(exceptView.frame, to: window)
            if ef.maxY > window.bounds.height / 2 {
                bottomAnchor.constraint(equalTo: exceptView.topAnchor).isActive = true
            } else {
                topAnchor.constraint(equalTo: exceptView.bottomAnchor).isActive = true
            }
            centerXAnchor.constraint(equalTo: exceptView.centerXAnchor).isActive = true
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let maxX = containerView.subviews.map { $0.frame.maxX }.max() ?? 0
        let maxY = containerView.subviews.map { $0.frame.maxY }.max() ?? 0
        return .init(width: maxX + shadowMargin * 2 + containerPadding, height: maxY + shadowMargin * 2 + containerPadding)
    }
    
    let shadowMargin: CGFloat = 10
    let maxRowPerLine: Int = 4
    let itemSize: CGSize = .init(width: 44, height: 44)
    let containerPadding = CGFloat(8)
    
    func rebuildFrom(views: [UIView]) {
        containerView.subviews.forEach {
            if !($0 is UIVisualEffectView) {
                $0.removeFromSuperview()
            }
        }
        setupFromItemViews(views: views)
    }
    
    func rebuildLayout() {
        var rowIndex: CGFloat = -1
        var lineIndex: CGFloat = -1
        let layoutViews = containerView.subviews.filter { !($0 is UIVisualEffectView) && !$0.isHidden }
        layoutViews.enumerated().forEach { index, view in
            let lastView: UIView? = index == 0 ? nil : layoutViews[index - 1]
            
            if view is UISlider {
                rowIndex = -1
                if rowIndex > 0 {
                    lineIndex += 1
                }
                let slideHeight: CGFloat = 44
                let inset: CGFloat = 8
                let width: CGFloat = itemSize.width * CGFloat(maxRowPerLine) - (2 * inset)
                let y = lastView?.frame.maxY ?? 0
                view.frame = .init(x: inset,
                                   y: y,
                                   width: width,
                                   height: slideHeight)
            } else {
                rowIndex = CGFloat(Int(rowIndex + 1) % maxRowPerLine)
                lineIndex = rowIndex == 0 ? lineIndex + 1 : lineIndex
                let beginX: CGFloat = containerPadding
                let beginY: CGFloat = containerPadding
                let x = rowIndex == 0 ? beginX : (lastView?.frame.maxX ?? 0)
                let y = rowIndex == 0 ? (lastView?.frame.maxY ?? beginY) : (lastView?.frame.minY ?? 0)
                view.frame = .init(x: x,
                                   y: y,
                                   width: itemSize.width,
                                   height: itemSize.height)
            }
        }
        invalidateIntrinsicContentSize()
    }
    
    func setupFromItemViews(views: [UIView]) {
        views.forEach { containerView.addSubview($0) }
        rebuildLayout()
    }
    
    func deselectAll() {
        containerView.subviews.forEach { ($0 as? UIButton)?.isSelected = false }
    }
    
    func getItemViews() -> [UIView] {
        containerView.subviews
    }
    
    lazy var containerView: HTSubPanelContainer = {
        let view = HTSubPanelContainer()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1 / UIScreen.main.scale
        
        view.autoresizesSubviews = true
        view.backgroundColor = .darkGray // TODO:
//        let effect: UIBlurEffect = .init(style: .regular)
//        let effectView = UIVisualEffectView(effect: effect)
//        view.addSubview(effectView)
//        effectView.frame = bounds
//        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.layer.addSublayer(line)
        return view
    }()
    
    lazy var line: CALayer = {
        let line = CALayer()
        line.backgroundColor = UIColor.lightGray.cgColor
        return line
    }()
}

extension HTSubPanelView: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
        if let _ = layer.animation(forKey: "show") {
            isHidden = false
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            if layer.animation(forKey: "show") === anim {
            } else {
                // dismiss
                isHidden = true
            }
            layer.removeAllAnimations()
        }
    }
}
