//
//  HTExtension.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

extension UIButton {
    func horizontalCenterTitleAndImageWith(_ spacing: CGFloat) {
        setDidLayoutHandle { [weak self] _ in
            guard let btn = self else { return }
            guard let label = btn.titleLabel else { return }
            let imageSize = btn.imageView?.bounds.size ?? .zero
            let text = label.text ?? ""
            let titleSize = NSString(string: text)
                .boundingRect(with: btn.bounds.size,
                              options: .usesLineFragmentOrigin,
                              attributes: [NSAttributedString.Key.font: label.font as Any],
                              context: nil)
                .size
            let totalWidth = imageSize.width + titleSize.width + spacing
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -(totalWidth - imageSize.width) * 2)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(totalWidth - titleSize.width) * 2, bottom: 0, right: 0)
        }
    }

    func verticalCenterImageAndTitleWith(_ spacing: CGFloat) {
        setDidLayoutHandle { [weak self] _ in
            guard let btn = self else { return }
            guard let label = btn.titleLabel else { return }
            let imageSize = btn.imageView?.bounds.size ?? .zero
            let text = label.text ?? ""
            let titleSize = NSString(string: text)
                .boundingRect(with: btn.bounds.size,
                              options: .usesLineFragmentOrigin,
                              attributes: [NSAttributedString.Key.font: label.font as Any],
                              context: nil)
                .size
            let totalHeight = imageSize.height + titleSize.height + spacing
            btn.imageEdgeInsets = UIEdgeInsets(top: -(totalHeight - imageSize.height), left: 0, bottom: 0, right: -titleSize.width)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(totalHeight - titleSize.height), right: 0)
        }
    }
}

extension UIView {
    func setDidLayoutHandle(_ handler: @escaping ((CGRect) -> Void)) {
        for view in subviews {
            if let inter = view as? InterView {
                inter.didLayoutHandler = handler
                inter.setNeedsLayout()
                return
            }
        }
        let host = InterView(handler: handler)
        addSubview(host)
        host.isUserInteractionEnabled = false
        host.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private class InterView: UIView {
    var didLayoutHandler: (CGRect) -> Void

    init(handler: @escaping ((CGRect) -> Void)) {
        didLayoutHandler = handler
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        didLayoutHandler(bounds)
    }
}
