//
//  ViewController.swift
//  Fastboard
//
//  Created by yunshi on 12/22/2021.
//  Copyright (c) 2021 yunshi. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard
import SnapKit

extension WhiteApplianceNameKey: CaseIterable {
    public static var allCases: [WhiteApplianceNameKey] {
        [.ApplianceClicker,
         .AppliancePencil,
         .ApplianceSelector,
         .ApplianceText,
         .ApplianceEllipse,
         .ApplianceRectangle,
         .ApplianceEraser,
         .ApplianceStraight,
         .ApplianceArrow,
         .ApplianceHand,
         .ApplianceLaserPointer
        ]
    }
}

extension WhiteApplianceShapeTypeKey: CaseIterable {
    public static var allCases: [WhiteApplianceShapeTypeKey] {
        [
            .ApplianceShapeTypeTriangle,
            .ApplianceShapeTypeRhombus,
            .ApplianceShapeTypePentagram,
            .ApplianceShapeTypeSpeechBalloon
        ]
    }
}

class ViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    var fastRoom: FastRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCustomApps()
    }
    
    func setupViews() {
        view.backgroundColor = .gray
        setupFastboard()
        setupBottomTools()
        setupMediaTools()
    }
    
    func setupCustomApps() {
        guard let js = Bundle.main.url(forResource: "monaco.iife", withExtension: "js")
        else { return }
        let jsCode = try! String(contentsOf: js)
        let params = WhiteRegisterAppParams(javascriptString: jsCode, kind: "Monaco", variable: "NetlessAppMonaco.default")
        fastRoom.whiteSDK.registerApp(with: params) { error in
            
        }
        				
        guard let youtubeJs = Bundle.main.url(forResource: "plyr.iife", withExtension: "js")
        else { return }
        let youtubeJsCode = try! String(contentsOf: youtubeJs)
        let youtubeParams = WhiteRegisterAppParams(javascriptString: youtubeJsCode, kind: "Plyr", variable: "NetlessAppPlyr.default")
        fastRoom.whiteSDK.registerApp(with: youtubeParams) { error in
            
        }
    }
    
    func setupFastboard(custom: FastRoomOverlay? = nil) {
        let config: FastRoomConfiguration = FastRoomConfiguration(appIdentifier: RoomInfo.APPID.value,
                                           roomUUID: RoomInfo.ROOMUUID.value,
                                           roomToken: RoomInfo.ROOMTOKEN.value,
                                           region: .CN,
                                           userUID: "some-unique-id")
        config.customOverlay = custom
        let fastRoom = Fastboard.createFastRoom(withFastRoomConfig: config)
        fastRoom.delegate = self
        let fastRoomView = fastRoom.view
        view.autoresizesSubviews = true
        view.addSubview(fastRoomView)
        let leftGuide = UILayoutGuide()
        let rightGuide = UILayoutGuide()
        view.addLayoutGuide(leftGuide)
        view.addLayoutGuide(rightGuide)
        leftGuide.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        rightGuide.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(fastRoomView.snp.right)
            make.width.equalTo(leftGuide)
            make.width.greaterThanOrEqualTo(0)
        }
        fastRoomView.snp.makeConstraints { make in
            make.left.equalTo(leftGuide.snp.right)
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(44)
            } else {
                make.top.equalToSuperview().inset(44)
            }
            make.width.greaterThanOrEqualTo(144)
            make.height.lessThanOrEqualToSuperview().inset(90)
            make.height.equalTo(fastRoomView.snp.width).multipliedBy(1 / Fastboard.globalFastboardRatio)
        }
        fastRoomView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let activity: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activity = UIActivityIndicatorView(style: .medium)
        } else {
            activity = UIActivityIndicatorView(style: .gray)
        }
        fastRoomView.addSubview(activity)
        activity.snp.makeConstraints { $0.center.equalToSuperview() }
        activity.startAnimating()
        exampleControlView.isHidden = true
        mediaControlView.isHidden = true
        fastRoom.joinRoom { _ in
            activity.stopAnimating()
            self.exampleControlView.isHidden = false
            self.mediaControlView.isHidden = false
        }
        self.fastRoom = fastRoom
    }
    
    func setupMediaTools() {
        view.addSubview(mediaControlView)
        mediaControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(fastRoom.view.snp.top)
            make.height.equalTo(44)
        }
    }
    
    func setupBottomTools() {
        view.addSubview(exampleControlView)
        exampleControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(fastRoom.view.snp.bottom)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalToSuperview()
            }
        }
    }
    
    func reloadFastboard(overlay: FastRoomOverlay? = nil) {
        fastRoom.view.removeFromSuperview()
        exampleControlView.removeFromSuperview()
        setupFastboard(custom: overlay)
        setupBottomTools()
    }
    
    var isHide = false {
        didSet {
            fastRoom.setAllPanel(hide: isHide)
            let str = NSLocalizedString(isHide ? "On" : "Off", comment: "")
            exampleItems.first(where: { $0.title == NSLocalizedString("Hide PanelItem", comment: "")})?.status = str
        }
    }
    
    var currentTheme: ExampleTheme = .auto {
        didSet {
            switch currentTheme {
            case .light:
                FastRoomThemeManager.shared.apply(FastRoomDefaultTheme.defaultLightTheme)
            case .dark:
                FastRoomThemeManager.shared.apply(FastRoomDefaultTheme.defaultDarkTheme)
            case .auto:
                if #available(iOS 13, *) {
                    FastRoomThemeManager.shared.apply(FastRoomDefaultTheme.defaultAutoTheme)
                } else {
                    return
                }
            }
        }
    }
    
    func applyNextTheme() -> ExampleTheme {
        let all = ExampleTheme.allCases
        let index = all.firstIndex(of: self.currentTheme)!
        if index == all.count - 1 {
            self.currentTheme = all.first!
        } else {
            let targetCurrentTheme = all[index + 1]
            if targetCurrentTheme == .auto {
                if #available(iOS 13, *) {
                    self.currentTheme = targetCurrentTheme
                } else {
                    self.currentTheme = all.first!
                }
            } else {
                self.currentTheme = targetCurrentTheme
            }
        }
        usingCustomTheme = false
        return self.currentTheme
    }
    
    var usingCustomTheme: Bool = false {
        didSet {
            if usingCustomTheme {
                FastRoomControlBar.appearance().itemWidth = 26
                FastRoomControlBar.appearance().commonRadius = 4
                FastRoomPanelItemButton.appearance().indicatorInset = .init(top: 0, left: 0, bottom: 3, right: 3)
                let white = FastRoomWhiteboardAssets(whiteboardBackgroundColor: .white,
                                             containerColor: .gray)
                let control = FastRoomControlBarAssets(backgroundColor: .init(hexString: customColor.controlBarBg),
                                               borderColor: .clear,
                                               effectStyle: .init(style: .regular))
                let panel = FastRoomPanelItemAssets(normalIconColor: .white,
                                                    selectedIconColor: .init(hexString: customColor.selColor),
                                                    selectedIconBgColor: .init(hexString: customColor.iconSelectedBgColor),
                                                    highlightColor: .init(hexString: customColor.highlightColor),
                                                    highlightBgColor: .clear,
                                                    disableColor: UIColor.gray.withAlphaComponent(0.7),
                                                    subOpsIndicatorColor: .white,
                                                    pageTextLabelColor: .white,
                                                    selectedBackgroundCornerradius: 0,
                                                    selectedBackgroundEdgeinset: .zero)
                let theme = FastRoomThemeAsset(whiteboardAssets: white,
                                       controlBarAssets: control,
                                       panelItemAssets: panel)
                FastRoomThemeManager.shared.apply(theme)
            } else {
                FastRoomPanelItemButton.appearance().indicatorInset = .init(top: 0, left: 0, bottom: 8, right: 8)
                FastRoomControlBar.appearance().commonRadius = 10
                FastRoomControlBar.appearance().itemWidth = 44
                let i = self.currentTheme
                self.currentTheme = i
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Update User Theme", comment: "") })?.status = NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: "")
        }
    }
    
    var storedColors: [UIColor] = FastRoomDefaultOperationItem.defaultColors
    var usingCustomPanelItemColor: Bool = false {
        didSet {
            if usingCustomPanelItemColor {
                FastRoomDefaultOperationItem.defaultColors = [.red, .yellow, .blue]
            } else {
                FastRoomDefaultOperationItem.defaultColors = storedColors
            }
            self.reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Custom Pencil Colors", comment: "") })?.status = NSLocalizedString(usingCustomPanelItemColor ? "On" : "Off", comment: "")
        }
    }
    
    var defaultPhoneItems = CompactFastRoomOverlay.defaultCompactAppliance
    var usingCustomPhoneItems = false {
        didSet {
            if usingCustomTheme {
                CompactFastRoomOverlay.defaultCompactAppliance = [.AppliancePencil, .ApplianceSelector, .ApplianceEraser]
            } else {
                CompactFastRoomOverlay.defaultCompactAppliance = defaultPhoneItems
            }
            reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Update iPhone Items", comment: "") })?.status = NSLocalizedString(usingCustomPhoneItems ? "On" : "Off", comment: "")
        }
    }
    
    var defaultPadItems = RegularFastRoomOverlay.customOperationPanel
    var usingCustomPadItems = false {
        didSet {
            if usingCustomPadItems {
                var items: [FastRoomOperationItem] = []
                let shape = SubOpsItem(subOps: RegularFastRoomOverlay.shapeItems)
                items.append(shape)
                items.append(FastRoomDefaultOperationItem.selectableApplianceItem(.AppliancePencil, shape: nil))
                items.append(FastRoomDefaultOperationItem.clean())
                let panel = FastRoomPanel(items: items)
                RegularFastRoomOverlay.customOperationPanel = {
                    return panel
                }
            } else {
                RegularFastRoomOverlay.customOperationPanel = defaultPadItems
            }
            reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Update Pad Items", comment: "") })?.status = NSLocalizedString(usingCustomPadItems ? "On" : "Off", comment: "")
        }
    }
    
    var usingCustomIcons = false {
        didSet {
            if usingCustomIcons {
                FastRoomThemeManager.shared.updateIcons(using: Bundle.main)
            } else {
                let path = Bundle(for: Fastboard.self).path(forResource: "Icons", ofType: "bundle")
                let bundle = Bundle(path: path!)!
                FastRoomThemeManager.shared.updateIcons(using: bundle)
            }
            AppearanceManager.shared.commitUpdate()
            reloadFastboard()
            view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.view.isUserInteractionEnabled = true
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Update Custom Icons", comment: "") })?.status = NSLocalizedString(usingCustomIcons ? "On" : "Off", comment: "")
        }
    }
    
    var usingCustomOverlay = false {
        didSet {
            if usingCustomOverlay {
                self.reloadFastboard(overlay: CustomFastboardOverlay())
                FastRoomControlBar.appearance().itemWidth = 66
                AppearanceManager.shared.commitUpdate()
            } else {
                reloadFastboard()
                FastRoomControlBar.appearance().itemWidth = 44
                AppearanceManager.shared.commitUpdate()
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Custom Overlay", comment: "")})?.status = NSLocalizedString(usingCustomOverlay ? "On" : "Off", comment: "")
        }
    }
    
    var hideAllPanel = false {
        didSet {
            fastRoom.view.overlay?.setAllPanel(hide: hideAllPanel)
        }
    }
    
    lazy var exampleItems: [ExampleItem] = {
        var array: [ExampleItem] = [
            .init(title: NSLocalizedString("Reset", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                let vc = ViewController()
                vc.usingCustomTheme = false
                UIApplication.shared.keyWindow?.rootViewController = vc
            }),
            .init(title: NSLocalizedString("Update Default Theme", comment: ""), status: "\(self.currentTheme)", clickBlock: { [unowned self] item in
                item.status = "\(self.applyNextTheme())"
            }),
            .init(title: NSLocalizedString("Update User Theme", comment: ""), status: NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomTheme = !self.usingCustomTheme
            }),
            .init(title: NSLocalizedString("Custom Pencil Colors", comment: ""), status: NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomPanelItemColor = !self.usingCustomPanelItemColor
            }),
            .init(title: NSLocalizedString("Update iPhone Items", comment: ""), status: NSLocalizedString(usingCustomPhoneItems ? "On" : "Off", comment: ""), clickBlock: { _ in
                self.usingCustomPhoneItems = !self.usingCustomPhoneItems
            }),
            .init(title: NSLocalizedString("Update Pad Items", comment: ""), status: NSLocalizedString(usingCustomPadItems ? "On" : "Off", comment: ""), clickBlock: { _ in
                self.usingCustomPadItems = !self.usingCustomPadItems
            }),
            .init(title: NSLocalizedString("Update ToolBar Direction", comment: ""), status: NSLocalizedString("Left", comment: ""), clickBlock: { [unowned self] item in
                if FastRoomView.appearance().operationBarDirection == .left {
                    FastRoomView.appearance().operationBarDirection = .right
                    item.status = NSLocalizedString("Right", comment: "")
                } else {
                    FastRoomView.appearance().operationBarDirection = .left
                    item.status = NSLocalizedString("Left", comment: "")
                }
                AppearanceManager.shared.commitUpdate()
            }),
            .init(title: NSLocalizedString("BarSize", comment: ""), status: "40", clickBlock: { item in
                if FastRoomControlBar.appearance().itemWidth == 48 {
                    FastRoomControlBar.appearance().itemWidth = 44
                } else {
                    FastRoomControlBar.appearance().itemWidth = 48
                }
                item.status = FastRoomControlBar.appearance().itemWidth.description
                AppearanceManager.shared.commitUpdate()
            }),
            .init(title: NSLocalizedString("Update Custom Icons", comment: ""), status: NSLocalizedString(usingCustomIcons ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomIcons = !self.usingCustomIcons
            }),
            .init(title: NSLocalizedString("Hide PanelItem", comment: ""), status: NSLocalizedString(isHide ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.isHide = !self.isHide
            }),
            .init(title: NSLocalizedString("Hide Item", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                let alert = UIAlertController(title: NSLocalizedString("Hide Item", comment: ""), message: "", preferredStyle: .actionSheet)
                var values: [FastRoomDefaultOperationIdentifier] = []
                values.append(contentsOf: WhiteApplianceNameKey.allCases.map { .applice(key: $0, shape: nil)})
                values.append(contentsOf: WhiteApplianceShapeTypeKey.allCases.map { .applice(key: .ApplianceShape, shape: $0) })
                let others: [FastRoomDefaultOperationIdentifier] = [
                    .operationType(.clean)!,
                    .operationType(.previousPage)!,
                    .operationType(.newPage)!,
                    .operationType(.nextPage)!,
                    .operationType(.redo)!,
                    .operationType(.undo)!
                ]
                values.append(contentsOf: others)
                for key in values {
                    alert.addAction(.init(title: key.identifier,
                                          style: .default, handler: { _ in
                        self.fastRoom.setPanelItemHide(item: key, hide: true)
                    }))
                }
                alert.addAction(.init(title: "cancel", style: .cancel, handler: nil))
                alert.popoverPresentationController?.sourceView = self.exampleControlView
                self.present(alert, animated: true, completion: nil)
            }),
            .init(title: NSLocalizedString("Update writable", comment: ""), status: NSLocalizedString("On", comment: ""), clickBlock: { [unowned self] item in
                guard let room = self.fastRoom.room else { return }
                let writable = !room.isWritable
                self.fastRoom.updateWritable(writable) { error in
                    if let error = error {
                        print(error)
                        return
                    }
                }
                item.status = NSLocalizedString(writable ? "On" : "Off", comment: "")
            }),
            .init(title: NSLocalizedString("Custom Overlay", comment: ""), status: NSLocalizedString("Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomOverlay = !self.usingCustomOverlay
            }),
            .init(title: NSLocalizedString("Apple Pencil", comment: ""), status: NSLocalizedString(FastRoom.followSystemPencilBehavior ? "On" : "Off", comment: ""), clickBlock: { [unowned self] item in
                FastRoom.followSystemPencilBehavior = !FastRoom.followSystemPencilBehavior
                item.status =
                NSLocalizedString(FastRoom.followSystemPencilBehavior ? "On" : "Off", comment: "")
            }),
            .init(title: NSLocalizedString("Update Layout", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                self.fastRoom.view.overlay?.invalidAllLayout()
                if let regular = self.fastRoom.view.overlay as? RegularFastRoomOverlay {
                    regular.operationPanel.view?.snp.makeConstraints { make in
                        make.left.equalToSuperview()
                        make.centerY.equalToSuperview()
                    }
                    
                    regular.deleteSelectionPanel.view?.snp.makeConstraints({ make in
                        make.bottom.equalTo(regular.operationPanel.view!.snp.top).offset(-8)
                        make.left.equalToSuperview()
                    })
                    
                    regular.undoRedoPanel.view?.snp.makeConstraints({ make in
                        make.left.bottom.equalTo(self.fastRoom.view.whiteboardView)
                    })
                    
                    regular.scenePanel.view?.snp.makeConstraints({ make in
                        make.bottom.equalTo(self.fastRoom.view.whiteboardView)
                        make.centerX.equalToSuperview()
                    })
                }
                
                if let compact = self.fastRoom.view.overlay as? CompactFastRoomOverlay {
                    compact.operationPanel.view?.snp.makeConstraints({ make in
                        make.left.equalTo(self.fastRoom.view.whiteboardView)
                        make.centerY.equalToSuperview()
                    })
                    
                    compact.colorAndStrokePanel.view?.snp.makeConstraints({ make in
                        make.left.equalTo(self.fastRoom.view.whiteboardView)
                        make.bottom.equalTo(compact.operationPanel.view!.snp.top).offset(-8)
                    })
                    
                    compact.deleteSelectionPanel.view?.snp.makeConstraints { $0.edges.equalTo(compact.colorAndStrokePanel.view!) }
                    
                    compact.undoRedoPanel.view?.snp.makeConstraints({ make in
                        make.left.bottom.equalTo(self.fastRoom.view.whiteboardView)
                    })
                    
                    compact.scenePanel.view?.snp.makeConstraints({ make in
                        make.bottom.centerX.equalTo(self.fastRoom.view.whiteboardView)
                    })
                }
            }),
            .init(title: NSLocalizedString("Hide All Panel", comment: ""), status: NSLocalizedString(self.hideAllPanel ? "On" : "Off", comment: ""), enable: true, clickBlock: { [unowned self] item in
                self.hideAllPanel = !self.hideAllPanel
                item.status = NSLocalizedString(self.hideAllPanel ? "On" : "Off", comment: "")
            })
        ]
        return array
    }()
    
    func insertItem(_ item: StorageItem) {
        if item.fileType == .img {
            URLSession.shared.downloadTask(with: URLRequest(url: item.fileURL)) { url, r, err in
                guard
                    let url = url,
                    let data = try? Data(contentsOf: url),
                    let img = UIImage(data: data)
                else {
                    return
                }
                self.fastRoom.insertImg(item.fileURL, imageSize: img.size)
            }.resume()
        }
        if item.fileType == .video ||
            item.fileType == .music {
            self.fastRoom.insertMedia(item.fileURL, title: item.fileName, completionHandler: nil)
            return
        }
        WhiteConverterV5.checkProgress(withTaskUUID: item.taskUUID,
                                       token: item.taskToken,
                                       region: item.region,
                                       taskType: item.taskType) { info, error in
            if let error = error {
                print(error)
                return
            }
            guard let info = info else { return }
            let pages = info.progress?.convertedFileList ?? []
            switch item.fileType {
            case .img, .music, .video:
                return
            case .word, .pdf:
                self.fastRoom.insertStaticDocument(pages,
                                                    title: item.fileName,
                                                    completionHandler: nil)
            case .ppt:
                if item.taskType == .dynamic {
                    self.fastRoom.insertPptx(pages,
                                              title: item.fileName,
                                              completionHandler: nil)
                } else {
                    self.fastRoom.insertStaticDocument(pages,
                                                        title: item.fileName,
                                                        completionHandler: nil)
                }
            default:
                return
            }
        }
    }
    
    // MARK: Lazy
    lazy var exampleControlView = ExampleControlView(items: exampleItems)
    
    lazy var mediaControlView = ExampleControlView(items: [
        .init(title: NSLocalizedString("Insert Mock PPTX", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.taskType == .dynamic }) {
                self.insertItem(item)
                self.fastRoom.room?.setViewMode(.broadcaster)
            }
        }),
        .init(title: NSLocalizedString("Insert Mock DOC", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .word }) { self.insertItem(item) }
        }),
        .init(title: NSLocalizedString("Insert Mock PDF", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .pdf }) { self.insertItem(item) }
        }),
        .init(title: NSLocalizedString("Insert Mock PPT", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .ppt && $0.taskType == .static })
            { self.insertItem(item) }
        }),
        .init(title: NSLocalizedString("Insert Mock MP4", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .video }) { self.insertItem(item) }
        }),
        .init(title: NSLocalizedString("Insert Mock MP3", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .music }) { self.insertItem(item) }
        }),
        .init(title: NSLocalizedString("Insert Mock Image", comment: ""), status: nil, clickBlock: { [unowned self] _ in
            if let item = storage.first(where: { $0.fileType == .img }) { self.insertItem(item) }
        }),
        .init(title: "VSCode", status: nil, enable: true, clickBlock: { [unowned self] _ in
            let options = WhiteAppOptions()
            options.title = "VSCode"
            let params = WhiteAppParam(kind: "Monaco", options: options, attrs: [:])
            self.fastRoom.room?.addApp(params, completionHandler: { _ in })
        }),
        .init(title: "Youtube", status: nil, enable: true, clickBlock: { [unowned self] _ in
            let options = WhiteAppOptions()
            options.title = "Youtube"
            let appParams = WhiteAppParam(kind: "Plyr",
                                          options: options,
                                          attrs: ["src": "https://www.youtube.com/embed/bTqVqk7FSmY",
                                                  "provider": "youtube"])
            self.fastRoom.room?.addApp(appParams, completionHandler: { _ in })
        })
    ])
}

extension ViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_ fastboard: FastRoom, room: WhiteRoom) {
        print(#function, room)
    }
    
    func fastboardPhaseDidUpdate(_ fastboard: FastRoom, phase: FastRoomPhase) {
        print(#function, phase)
    }
    
    func fastboardUserKickedOut(_ fastboard: FastRoom, reason: String) {
        print(#function, reason)
    }
    
    func fastboardDidOccurError(_ fastboard: FastRoom, error: FastRoomError) {
        print(#function, error.localizedDescription)
    }
}
