//
//  BoardHelper.swift
//
//
//  Created by ZYP on 2023/10/20.
//

import UIKit
import Fastboard
import Whiteboard

protocol BoardHelperDelegate: NSObjectProtocol {
    func boardHelperLog(text: String)
}

class BoardHelper: NSObject {
    private weak var fastRoom: FastRoom?
    private var list = [BoardListItem]()
    private let defaultDir = "/"
    private let divideStr = "|"
    weak var delegate: BoardHelperDelegate?
    
    public init(fastRoom: FastRoom, delegate: BoardHelperDelegate?) {
        self.fastRoom = fastRoom
        self.delegate = delegate
    }
    
    deinit {
        log(text: "[I]: deinit")
    }
    
    /// 获取当前列表
    public func getWhiteBoardList() -> [BoardListItem] {
        return list
    }
    
    public func setWhiteBoardList(list: [BoardListItem]) {
        self.list = list
    }
    
    /// 添加一个白板
    /// - Parameters:
    ///   - path: 如果是白板，给唯一标识符。如果文件就给文件名称
    ///   - scenes: 内容
    /// - Returns: `true`表示调用成功
    func addWhiteBoard(path: String, scenes: [Scene]) -> Bool {
        guard let fastRoom = fastRoom else {
            log(text: "[I]: fastRoom is nil")
            return false
        }
        guard !path.isEmpty || !scenes.isEmpty else {
            log(text: "[E]: path or scenes of param is empty")
            return false
        }
        
        let newScenes = scenes.map({ $0.toWhiteScene(prefix: "\(path)\(divideStr)") })
        
        let type = getBoardItemType(path: path)
        let item = BoardListItem(id: path,
                                 name: path,
                                 status: .inactive,
                                 scale: 1,
                                 totalPage: UInt(newScenes.count),
                                 activityPage: 0,
                                 type: type)
        list.append(item)
        fastRoom.room?.putScenes(defaultDir, scenes: newScenes, index: UInt.max)
        log(text: "[I]: did put scene at path:\(path)")
        return true
    }
    
    /// 切换白板
    /// - Parameters:
    ///   - path: 同`addWhiteBoard`的`path`
    ///   - page: 页面索引值，`addWhiteBoard`方法中`scenes`数组的索引
    /// - Returns: `true`表示调用成功
    public func switchWhiteBoard(path: String, page: UInt) -> Bool {
        guard let fastRoom = fastRoom else {
            log(text: "[I]: fastRoom is nil")
            return false
        }
        let item = list.first { item in
            item.id == path
        }
        
        guard let item = item else {
            log(text: "[E]: can not find item of path:\(path)")
            return false
        }
        
        let dir = defaultDir
        fastRoom.room?.getEntireScenes({ [weak self] dic in
            guard let scenes = dic[dir] else {
                return
            }
            guard let self = self else {
                return
            }
            
            if page >= scenes.count {
                log(text: "[E]: can not find page:\(page)")
                log(text: "[E]: \(scenes.map({ $0.name }))")
                return
            }
            
            let targetName = path + "|" + "\(page)"
            
            let targetIndex = scenes.firstIndex { scene in
                scene.name == targetName
            }
            
            guard targetIndex != nil else {
                log(text: "[E]: can not find targetIndex \(targetName)")
                log(text:"[E]:\(scenes.map({ $0.name }))")
                return
            }
            let index = Int(targetIndex!)
            
            fastRoom.view.whiteboardView.evaluateJavaScript("window.manager.setMainViewSceneIndex(\(index))")
            log(text: "[D]: did setMainViewSceneIndex \(index)")
            
            for info in list {
                info.activityPage = item.id == info.id ? page : 0
                info.status = item.id == info.id ? .active : .inactive
            }
        })
        return true
    }
    
    
    /// 销毁具体的白板，`addWhiteBoard`的反操作
    /// - Parameter path: 同`addWhiteBoard`的`path`
    public func destoryWhiteBoard(path: String) {
        guard let fastRoom = fastRoom else {
            log(text: "[I]: fastRoom is nil")
            return
        }
        let dir = defaultDir
        fastRoom.room?.getEntireScenes({ [weak self] dic in
            guard let scenes = dic[dir] else {
                return
            }
            guard let self = self else {
                return
            }
            let targetNamePrefix = path + "|"
            
            let removes = scenes.filter({ $0.name.hasPrefix(targetNamePrefix) })
            
            /** 1.切换 **/
            if let result = list.enumerated().first(where: { $0.element.status == .active }) {
                if result.element.name == path, list.count > 1 { /** 有2个以上的元素，才会切换 */
                    /// 需要切换到下一个
                    let changeToIndex = result.offset == list.count - 1 ? 0: result.offset + 1
                    let changeToItem = list[changeToIndex]
                    let ret = switchWhiteBoard(path: changeToItem.name,
                                               page: 0)
                    if !ret {
                        log(text: "[E]: switchWhiteBoard fail")
                    }
                }
            }
            
            /** 1.移除 **/
            for re in removes {
                fastRoom.room?.removeScenes(dir + re.name)
                list.removeAll { item in
                    item.id == re.name
                }
            }
        })
    }
    
    private func getBoardItemType(path: String) -> BoardItemType {
        if path.isEmpty {
            return .whiteboard
        }
        
        let splits = path.split(separator: ".")
        if splits.count == 1 {
            return .whiteboard
        }
        
        if let type = BoardItemType(rawValue: String(splits.last!)) {
            return type
        }
        
        return .whiteboard
    }
    
    private func log(text: String) {
        delegate?.boardHelperLog(text: text)
    }
}

extension BoardHelper {
    /// 和WhiteScene对应
    struct Scene {
        let name: String
        let ppt: PptPage?
        
        func toWhiteScene(prefix: String) -> WhiteScene {
            return WhiteScene(name: prefix + name, ppt: ppt?.toWhitePptPage)
        }
    }
    /// 和PPT对应
    struct PptPage {
        let src: String
        let previewUrl: String?
        let size: CGSize
        
        init(src: String, previewUrl: String? = nil, size: CGSize) {
            self.src = src
            self.previewUrl = previewUrl
            self.size = size
        }
        
        var toWhitePptPage: WhitePptPage {
            if let previewUrl = previewUrl {
                return WhitePptPage(src: src, preview: previewUrl, size: size)
            }
            return WhitePptPage(src: src, size: size)
        }
    }
    
    enum BoardItemStatus: UInt8 {
        case active
        case inactive
    }
    
    enum BoardItemType: String {
        case whiteboard = "whiteboard"
        case ppt = "ppt"
        case pptx = "pptx"
        case doc = "doc"
        case pdf = "pdf"
        case png = "png"
        case jpg = "jpg"
        case gif = "gif"
    }
    
    class BoardListItem {
        let id: String
        let name: String
        var status: BoardItemStatus
        let scale: Int
        let totalPage: UInt
        /// 当前活跃的页面
        var activityPage: UInt
        /// 类型
        let type: BoardItemType
        
        init(id: String, name: String, status: BoardItemStatus, scale: Int, totalPage: UInt, activityPage: UInt, type: BoardItemType) {
            self.id = id
            self.name = name
            self.status = status
            self.scale = scale
            self.totalPage = totalPage
            self.activityPage = activityPage
            self.type = type
        }
    }
}
