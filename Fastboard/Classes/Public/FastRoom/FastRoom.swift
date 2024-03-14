//
//  Fastboard.swift
//  Fastboard
//
//  Created by xuyunshi on 2021/12/29.
//

import UIKit
import Whiteboard

let pencilBehaviorUpdateNotificationName = Notification.Name("pencilBehaviorUpdateNotificationName")

/// Representing whiteboard object.
public class FastRoom: NSObject {
    /// Change this value to indicate if pencil will follow the system preference
    /// And this variable will only effect on iPad (Which has no compact sizeClass)
    /// Default is true
    @objc
    public static var followSystemPencilBehavior = true {
        didSet {
            NotificationCenter.default.post(name: pencilBehaviorUpdateNotificationName, object: nil)
        }
    }
    
    /// The view you should add to your viewController
    @objc
    public let view: FastRoomView
    
    /// The whiteSDK object, do not update it's delegate directly
    /// using 'commonDelegate' instead
    @objc
    public var whiteSDK: WhiteSDK!
    
    /// The whiteRoom object, do not update it's delegate directly
    /// using 'roomDelegate' instead
    @objc
    public var room: WhiteRoom? {
        didSet {
            if let room {
                view.overlay?.setupWith(room: room, fastboardView: view, direction: view.operationBarDirection)
                delegate?.fastboardDidSetupOverlay?(self, overlay: view.overlay)
            }
            initStateAfterJoinRoom()
            if !view.traitCollection.hasCompact {
                prepareForSystemPencilBehavior()
            }
        }
    }
    
    /// The delegate of fastboard
    /// Wrapped the whiteRoom and whiteSDK event
    @objc
    public weak var delegate: FastRoomDelegate?
    
    /// Proxy for whiteSDK delegate
    @objc
    public var commonDelegate: WhiteCommonCallbackDelegate? {
        get { sdkDelegateProxy.target as? WhiteCommonCallbackDelegate }
        set { sdkDelegateProxy.target = newValue }
    }

    /// Proxy for whiteRoom delegate
    @objc
    public var roomDelegate: WhiteRoomCallbackDelegate? {
        get { roomDelegateProxy.target as? WhiteRoomCallbackDelegate }
        set { roomDelegateProxy.target = newValue }
    }

    let roomConfig: WhiteRoomConfig
    
    weak var audioMixerDelegate: FastAudioMixerDelegate?
    
    lazy var roomDelegateProxy = WhiteRoomCallBackDelegateProxy.target(nil, middleMan: self)
    lazy var sdkDelegateProxy = WhiteCommonCallbackDelegateProxy.target(nil, middleMan: self)
    
    // MARK: - Public
    
    /// Call the method to join the whiteRoom
    @objc public func joinRoom() {
        joinRoom(completionHandler: nil)
    }
    
    @objc
    public func disconnectRoom() {
        room?.disconnect(nil)
    }
    
    @objc
    public func updateWritable(_ writable: Bool, completion: ((Error?) -> Void)?) {
        room?.setWritable(writable, completionHandler: { [weak room, weak self] success, error in
            if success, writable {
                room?.disableSerialization(false)
                
                // Get latest color when set writable true
                if writable, let colorNumbers = room?.state.memberState?.strokeColor {
                    let color = UIColor(numberArray: colorNumbers)
                    self?.view.overlay?.update(strokeColor: color)
                }
            }
            completion?(error)
        })
    }
    
    /// Call the method to join the whiteRoom
    public func joinRoom(completionHandler: ((Result<WhiteRoom, FastRoomError>) -> Void)? = nil) {
        delegate?.fastboardPhaseDidUpdate(self, phase: .connecting)
        whiteSDK.joinRoom(with: roomConfig,
                          callbacks: roomDelegateProxy) { [weak self] _, room, error in
            guard let self else { return }
            if let error {
                let fastError = FastRoomError(type: .joinRoom, error: error)
                self.delegate?.fastboardDidOccurError(self, error: fastError)
                completionHandler?(.failure(fastError))
                return
            }
            guard let room else {
                let fastError = FastRoomError(type: .joinRoom, info: ["info": "join success without room"])
                self.delegate?.fastboardDidOccurError(self, error: fastError)
                completionHandler?(.failure(fastError))
                return
            }
            room.disableSerialization(false)
            self.room = room
            completionHandler?(.success(room))
            self.delegate?.fastboardDidJoinRoomSuccess(self, room: room)
        }
    }
    
    // MARK: - Notification

    @objc func onThemeManagerTeleBoxThemeUpdate(_ notification: Notification) {
        guard let theme = notification.userInfo?["theme"] as? WhiteTeleBoxManagerThemeConfig else { return }
        room?.setTeleBoxTheme(theme)
    }
    
    @objc func onThemeManagerPrefersSchemeUpdate(_ notification: Notification) {
        guard let scheme = notification.userInfo?["scheme"] as? WhitePrefersColorScheme else { return }
        room?.setPrefersColorScheme(scheme)
    }
    
    // MARK: - Private

    func initStateAfterJoinRoom() {
        guard let state = room?.state else { return }
        if let appliance = state.memberState?.currentApplianceName {
            view.overlay?.initUIWith(appliance: appliance, shape: state.memberState?.shapeType)
        } else {
            view.overlay?.initUIWith(appliance: nil, shape: nil)
        }
        
        view.overlay?.update(boxState: state.windowBoxState)
        
        if let pageState = state.pageState {
            view.overlay?.update(pageState: pageState)
        }
        
        if let strokeWidth = state.memberState?.strokeWidth?.floatValue {
            view.overlay?.update(strokeWidth: strokeWidth)
        }
        
        if let pencilEraserSize = state.memberState?.pencilEraserSize?.floatValue {
            view.overlay?.update(pencilEraserWidth: pencilEraserSize)
        }
        
        if let nums = state.memberState?.strokeColor {
            let color = UIColor(numberArray: nums)
            view.overlay?.update(strokeColor: color)
        }
    }
    
    /// Create a Fastboard with FastConfiguration
    /// - Parameter configuration: Configuration for fastboard
    @objc
    convenience init(configuration: FastRoomConfiguration) {
        func defaultOverlay() -> FastRoomOverlay {
            if UIScreen.main.traitCollection.hasCompact {
                return CompactFastRoomOverlay()
            } else {
                return RegularFastRoomOverlay()
            }
        }
        let fastboardOverlay = configuration.customOverlay ?? defaultOverlay()
        let fastboardView = FastRoomView(overlay: fastboardOverlay, customUrl: configuration.customWhiteboardUrl)
        self.init(view: fastboardView,
                  roomConfig: configuration.whiteRoomConfig,
                  sdkConfig: configuration.whiteSdkConfiguration,
                  audioMixerDelegate: configuration.audioMixerDelegate)
    }
    
    init(view: FastRoomView,
         roomConfig: WhiteRoomConfig,
         sdkConfig: WhiteSdkConfiguration,
         audioMixerDelegate: FastAudioMixerDelegate? = nil)
    {
        self.view = view
        self.roomConfig = roomConfig
        self.audioMixerDelegate = audioMixerDelegate
        super.init()
        let whiteSDK = WhiteSDK(whiteBoardView: view.whiteboardView,
                                config: sdkConfig,
                                commonCallbackDelegate: sdkDelegateProxy,
                                audioMixerBridgeDelegate: audioMixerDelegate == nil ? nil : self)
        self.whiteSDK = whiteSDK
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeManagerPrefersSchemeUpdate), name: prefersSchemeUpdateNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeManagerTeleBoxThemeUpdate), name: teleboxThemeUpdateNotificationName, object: nil)
    }
}

extension FastRoom: WhiteCommonCallbackDelegate {
    public func logger(_ dict: [AnyHashable : Any]) {}
    
    public func throwError(_ error: Error) {}
    
    public func sdkSetupFail(_ error: Error) {
        delegate?.fastboardDidOccurError(self, error: .init(type: .setupSDK, error: error))
    }
}

extension FastRoom: WhiteRoomCallbackDelegate {
    public func firePhaseChanged(_ phase: WhiteRoomPhase) {
        let fastPhase = FastRoomPhase(rawValue: phase.rawValue) ?? .unknown
        view.overlay?.update(roomPhase: fastPhase)
        delegate?.fastboardPhaseDidUpdate(self, phase: fastPhase)
    }
    
    public func fireRoomStateChanged(_ modifyState: WhiteRoomState!) {
        if let pageState = modifyState.pageState {
            view.overlay?.update(pageState: pageState)
        }
        if let boxState = modifyState.windowBoxState {
            view.overlay?.update(boxState: boxState)
        }
    }
    
    public func fireDisconnectWithError(_ error: String!) {
        delegate?.fastboardDidOccurError(self, error: .init(type: .disconnected, info: ["info": error ?? ""]))
    }
    
    public func fireKicked(withReason reason: String!) {
        delegate?.fastboardUserKickedOut(self, reason: reason)
    }
    
    public func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        view.overlay?.update(undoEnable: canUndoSteps > 0)
    }
    
    public func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        view.overlay?.update(redoEnable: canRedoSteps > 0)
    }
}

extension FastRoom: WhiteAudioMixerBridgeDelegate {
    public func startAudioMixing(_ filePath: String, loopback: Bool, replace: Bool, cycle: Int) {
        guard let mixer = whiteSDK.audioMixer else { return }
        audioMixerDelegate?.startAudioMixing(audioBridge: mixer, filePath: filePath, loopback: loopback, replace: replace, cycle: cycle)
    }
    
    public func stopAudioMixing() {
        guard let mixer = whiteSDK.audioMixer else { return }
        audioMixerDelegate?.stopAudioMixing(audioBridge: mixer)
    }
    
    public func pauseAudioMixing() {
        guard let mixer = whiteSDK.audioMixer else { return }
        audioMixerDelegate?.pauseAudioMixing(audioBridge: mixer)
    }
    
    public func resumeAudioMixing() {
        guard let mixer = whiteSDK.audioMixer else { return }
        audioMixerDelegate?.resumeAudioMixing(audioBridge: mixer)
    }
    
    public func setAudioMixingPosition(_ position: Int) {
        guard let mixer = whiteSDK.audioMixer else { return }
        audioMixerDelegate?.setAudioMixingPosition(audioBridge: mixer, position)
    }
}

public extension FastRoom {
    /// Only valid for `RegularFastRoomOverlay` yet.
    func prevColor() -> UIColor? {
        guard
            let overlay = view.overlay as? RegularFastRoomOverlay,
            let room
        else { return nil }
        let identifier = room.memberState.currentApplianceName.rawValue
        let subOps = overlay.operationPanel.items.compactMap { $0 as? SubOpsItem }
        if let op = subOps.first(where: { ($0.identifier ?? "").contains(identifier)}) {
            if op.needColor {
                let colors = op.subOps.compactMap({ $0 as? ColorItem })
                if let index = colors.firstIndex(where: { $0 === op.selectedColorItem }) {
                    let prevColor = colors[index == 0 ? colors.count - 1 : index - 1]
                    prevColor.onClick()
                    return prevColor.color
                }
            }
        }
        return nil
    }
    
    /// Only valid for `RegularFastRoomOverlay` yet.
    func nextColor() -> UIColor? {
        guard
            let overlay = view.overlay as? RegularFastRoomOverlay,
            let room
        else { return nil }
        let identifier = room.memberState.currentApplianceName.rawValue
        let subOps = overlay.operationPanel.items.compactMap { $0 as? SubOpsItem }
        if let op = subOps.first(where: { ($0.identifier ?? "").contains(identifier)}) {
            if op.needColor {
                let colors = op.subOps.compactMap({ $0 as? ColorItem })
                if let index = colors.firstIndex(where: { $0 === op.selectedColorItem }) {
                    let nextColor = colors[index == colors.count - 1 ? 0 : index + 1]
                    nextColor.onClick()
                    return nextColor.color
                }
            }
        }
        return nil
    }
    
    /// Only valid for `RegularFastRoomOverlay` yet.
    func updateApplianceIdentifier(_ identifier: String) {
        guard let overlay = view.overlay as? RegularFastRoomOverlay else { return }
        let subOps = overlay.operationPanel.items.compactMap { $0 as? SubOpsItem }
        for op in subOps {
            let contains = (op.identifier ?? "").contains(identifier)
            if contains {
                overlay.active(item: op, withSubPanel: op.expand)
                if let i = op.subOps.first(where: { ($0.identifier ?? "").contains(identifier)}) as? ApplianceItem {
                    i.onClick(i.button)
                }
                return
            }
        }
        let applianceItems = overlay.operationPanel.items.compactMap { $0 as? ApplianceItem }
        if let item = applianceItems.first(where: { $0.identifier?.contains(identifier) ?? false }) {
            overlay.active(item: item, withSubPanel: false)
        }
    }
}
