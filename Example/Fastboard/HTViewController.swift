//
//  HTViewController.swift
//  Fastboard
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Fastboard
import UIKit
import Whiteboard

class HTViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    var fastRoom: FastRoom!
    var editingTextId: String?
    var lastEdtingTextPoint: CGPoint?
    var lastInsertTextCameraCenter: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        performJoinRoom()
        setupGesture()
        applyTheme()

        // DEBUG
        helpFunction()
    }

    @objc func onSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            fastRoom.room?.dispatchDocsEvent(.nextPage, options: nil, completionHandler: { _ in })
        case .right:
            fastRoom.room?.dispatchDocsEvent(.prevPage, options: nil, completionHandler: { _ in })
        default: return
        }
    }

    func setupGesture() {
        fastRoom.view.addGestureRecognizer(leftSwipeGesture)
        fastRoom.view.addGestureRecognizer(rightSwipeGesture)
    }

    func helpFunction() {
        let btn = UIButton(type: .system)
        view.addSubview(btn)
        btn.setTitle("Insert Debug ppt", for: .normal)
        btn.addTarget(self, action: #selector(addTestPPT), for: .touchUpInside)
        btn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(44)
            make.centerX.equalToSuperview()
        }

        let closeBtn = UIButton(type: .system)
        view.addSubview(closeBtn)
        closeBtn.setTitle("Close All", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeAll), for: .touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(88)
            make.centerX.equalToSuperview()
        }
    }

    @objc func closeAll() {
        fastRoom.room?.queryAllApps(completionHandler: { dic, error in
            if let _ = error { return }
            dic.keys.forEach {
                self.fastRoom.room?.closeApp($0, completionHandler: {})
            }
        })
    }

    func insertDefaultTextWithCurrentCamera(centerX: CGFloat, centerY: CGFloat) {
        let x: CGFloat
        let y: CGFloat
        let cameraModified = lastInsertTextCameraCenter?.x != centerX || lastInsertTextCameraCenter?.y != centerY
        if !cameraModified, let lastEdtingTextPoint { // Camera not modified && not first text.
            let yLevel: CGFloat = 18
            let delta = lastEdtingTextPoint.y - centerY
            if delta >= 3 * yLevel {
                x = centerX
                y = centerY
            } else {
                x = lastEdtingTextPoint.x + 34
                y = lastEdtingTextPoint.y + yLevel
            }
        } else {
            x = centerX
            y = centerY
        }
        lastEdtingTextPoint = .init(x: x, y: y)
        lastInsertTextCameraCenter = .init(x: centerX, y: centerY)
        fastRoom.room?.insertText(x, y: y, textContent: "文本", completionHandler: { [weak self] id in
            guard let self else { return }
            self.editingTextId = id
            self.view.addSubview(self.textApplianceInputTextfield)
            self.textApplianceInputTextfield.inputAccessoryView = self.textApplianceInputTextfield
            self.textApplianceInputTextfield.becomeFirstResponder()
            self.textApplianceInputTextfield.text = "文本"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.textApplianceInputTextfield.isHidden = false
            }
        })
    }
    
    @objc func onTextTap() {
        fastRoom.view.overlay?.dismissAllSubPanels()
        fastRoom.view.whiteboardView.evaluateJavaScript("window.manager.focusedView.camera") { [weak self] state, error in
            guard let self else { return }
            if let error { return }
            guard let dic = state as? [String: CGFloat],
                  let centerX = dic["centerX"],
                  let centerY = dic["centerY"] else { return }
            self.insertDefaultTextWithCurrentCamera(centerX: centerX, centerY: centerY)
        }
    }

    @objc func onClickTextFinish() {
        textApplianceInputTextfield.resignFirstResponder()
        textApplianceInputTextfield.isHidden = true
        let m = WhiteMemberState()
        m.currentApplianceName = .ApplianceSelector
        fastRoom.room?.setMemberState(m)
    }

    @objc func onTextUpdate() {
        guard let text = textApplianceInputTextfield.text, let editingTextId else { return }
        if text.isEmpty {
            fastRoom.room?.updateText(editingTextId, textContent: " ")
            return
        }
        fastRoom.room?.updateText(editingTextId, textContent: text)
    }

    lazy var textApplianceInputTextfield: UITextField = {
        let leftInset = CGFloat(24)
        let borderVerticalInset = CGFloat(8)
        let tfHeight = CGFloat(50)

        let tf = UITextField(frame: .init(origin: .zero, size: .init(width: 1, height: tfHeight)))
        tf.addTarget(self, action: #selector(onTextUpdate), for: .editingChanged)
        tf.delegate = self
        tf.backgroundColor = .white
        tf.leftViewMode = .always
        tf.leftView = UIView(frame: .init(x: 0, y: 0, width: leftInset, height: 1))

        let border = CAShapeLayer()
        let borderWidth = UIScreen.main.bounds.width - leftInset - 36
        let borderHeight = tfHeight - borderVerticalInset * 2
        let path = UIBezierPath(roundedRect: .init(origin: .zero, size: .init(width: borderWidth, height: borderHeight)), cornerRadius: borderHeight / 2)

        border.path = path.cgPath
        border.lineWidth = 0.5
        border.strokeColor = UIColor.lightGray.cgColor
        border.fillColor = UIColor.clear.cgColor
        tf.layer.addSublayer(border)
        border.frame = .init(origin: .init(x: leftInset - 14, y: borderVerticalInset), size: .init(width: borderWidth, height: borderHeight))

        let r = UIButton(type: .system)
        r.frame = .init(origin: .zero, size: .init(width: 88, height: 44))
        r.setTitle("完成", for: .normal)
        r.addTarget(self, action: #selector(onClickTextFinish), for: .touchUpInside)
        r.contentEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 14)
        tf.rightView = r
        tf.rightViewMode = .always
        return tf
    }()

    @objc func addTestPPT() {
//        fastRoom.insertPptx(
//            uuid: "73cceb3365f44264a5bdb3907bf16056",
//            url: "https://convertcdn.netless.link/dynamicConvert",
//            title: "Test PPT") { appId in
//            }
        fastRoom.insertStaticDocument([.init(src: "https://www.shengwang.cn/_cache_58cd/content/1%E4%BA%A7%E5%93%81%E7%9F%A9%E9%98%B5-4311110000097040.jpeg", size: .init(width: 420, height: 420))], title: "fff")
    }

    func setupViews() {
        WhiteWebViewInjection.allowDisplayingKeyboardWithoutUserAction(false)
        view.backgroundColor = .gray
        let windowRatio: CGFloat = htContainerRatio
        let config = FastRoomConfiguration(appIdentifier: RoomInfo.APPID.value,
                                           roomUUID: RoomInfo.ROOMUUID.value,
                                           roomToken: RoomInfo.ROOMTOKEN.value,
                                           region: .CN,
                                           userUID: "some-unique-id-xxx")
        Fastboard.globalFastboardRatio = windowRatio
        config.customOverlay = HTOverlay(textTap: { [weak self] in
            self?.onTextTap()
        })
        config.whiteRoomConfig.windowParams?.fullscreen = true
        let fastRoom = Fastboard.createFastRoom(withFastRoomConfig: config)
        fastRoom.delegate = self
        let fastRoomView = fastRoom.view
        fastRoomView.backgroundColor = .black
        view.autoresizesSubviews = true
        view.addSubview(fastRoomView)
        fastRoomView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(fastRoomView.snp.width).multipliedBy(1 / windowRatio)
        }
        self.fastRoom = fastRoom

        view.addSubview(drawingButton)
        drawingButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func applyTheme() {
        let customTheme = FastRoomDefaultTheme.defaultDarkTheme
        customTheme.controlBarAssets = .init(backgroundColor: .clear, borderColor: .clear)
        customTheme.panelItemAssets.selectedIconColor = .cyan
        customTheme.panelItemAssets.highlightColor = .cyan
        FastRoomControlBar.appearance().borderWidth = 0
        FastRoomControlBar.appearance().commonRadius = 0
        FastRoomControlBar.appearance().itemWidth = view.bounds.width / 7

        FastRoomThemeManager.shared.updateIcons(using: .main)
        FastRoomThemeManager.shared.apply(customTheme)
    }

    func performJoinRoom() {
        let activity: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .medium)
            activity.color = .white
        } else {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        }
        fastRoom.view.addSubview(activity)
        activity.snp.makeConstraints { $0.center.equalToSuperview() }
        drawingButton.isHidden = true
        activity.startAnimating()
        fastRoom.joinRoom { [weak self] _ in
            self?.drawingButton.isHidden = false
            self?.update(editable: false)
            activity.stopAnimating()

            let m = WhiteMemberState()
            m.strokeColor = [255, 0, 0]
            m.textColor = UIColor.red.getNumbersArray()
            m.textSize = 16
            self?.fastRoom.room?.setMemberState(m)
            self?.fastRoom.view.overlay?.update(strokeColor: .red)
        }
    }

    func update(editable: Bool) {
        fastRoom.setAllPanel(hide: !editable)
        fastRoom.room?.disableDeviceInputs(!editable)
        [rightSwipeGesture, leftSwipeGesture]
            .forEach { $0.isEnabled = !editable }
    }

    @objc
    func onClickDrawing(_ sender: UIButton) {
        sender.isSelected.toggle()

        let editing = sender.isSelected
        sender.backgroundColor = editing ? .lightGray : .clear
        sender.tintColor = editing ? .darkGray : .lightGray
        update(editable: editing)
    }

    lazy var drawingButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(onClickDrawing), for: .touchUpInside)
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        }
        btn.tintColor = .lightGray
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 4
        return btn
    }()

    lazy var leftSwipeGesture: UISwipeGestureRecognizer = {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeGesture))
        swipe.direction = .left
        swipe.delegate = self
        return swipe
    }()

    lazy var rightSwipeGesture: UISwipeGestureRecognizer = {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeGesture))
        swipe.direction = .right
        swipe.delegate = self
        return swipe
    }()
}

extension HTViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }
}

extension HTViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_: FastRoom, room _: WhiteRoom) {}

    func fastboardDidOccurError(_: FastRoom, error _: FastRoomError) {}

    func fastboardUserKickedOut(_: FastRoom, reason _: String) {}

    func fastboardPhaseDidUpdate(_: FastRoom, phase _: FastRoomPhase) {}
}

extension HTViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        onClickTextFinish()
        return true
    }
}
