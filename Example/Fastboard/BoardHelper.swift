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
    private let fastRoom: FastRoom
    private var list = [BoardListItem]()
    private let defaultDir = "/"
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
    func addWhiteBoard(path: String, scenes: [WhiteScene]) -> Bool {
        guard !path.isEmpty || !scenes.isEmpty else {
            log(text: "[E]: path or scenes of param is empty")
            return false
        }
        let type = getBoardItemType(path: path)
        let item = BoardListItem(id: path,
                                 name: path,
                                 status: .inactive,
                                 scale: 1,
                                 totalPage: UInt(scenes.count),
                                 activityPage: 0,
                                 type: type)
        list.append(item)
        fastRoom.room?.putScenes(defaultDir, scenes: scenes, index: UInt.max)
        log(text: "[I]: did put scene at path:\(path)")
        return true
    }
    
    /// 切换白板
    /// - Parameters:
    ///   - path: 同`addWhiteBoard`的`path`
    ///   - page: 页面索引值，`addWhiteBoard`方法中`scenes`数组的索引
    /// - Returns: `true`表示调用成功
    public func switchWhiteBoard(path: String, page: UInt) -> Bool {
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
            
            
            if let result = list.enumerated().first(where: { $0.element.status == .active }) {
                /** 检查当前活跃的是不是要删除的那个 **/
                if result.element.name == path {
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
            
            for re in removes {
                fastRoom.room?.removeScenes(dir + re.name)
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
