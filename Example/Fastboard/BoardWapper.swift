//
//  BoardWapper.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/10/20.
//

import UIKit
import Fastboard
import Whiteboard

class BoardWapper: NSObject {
    // 定义 fastRoom 变量
    private let fastRoom: FastRoom
    private var list = [BoardListItem]()
    private let defaultDir = "/"
    
    init(fastRoom: FastRoom) {
        self.fastRoom = fastRoom
    }
    
    func getWhiteBoardList() -> [BoardListItem] {
        return list
    }
    
    func addWhiteBoard(path: String, scenes: [WhiteScene]) {
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
        print("did put scene at path:\(path)")
    }
    
    func switchWhiteBoard(path: String, page: UInt) {
        let item = list.first { item in
            item.id == path
        }
        
        guard let item = item else {
            print("[E]: can not find item of path:\(path)")
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
            
            if page >= scenes.count {
                print("[E]: can not find page:\(page)")
                print("\(scenes.map({ $0.name }))")
                return
            }
            
            let targetName = path + "|" + "\(page)"
            
            let targetIndex = scenes.firstIndex { scene in
                scene.name == targetName
            }
            
            guard targetIndex != nil else {
                print("can not find targetIndex \(targetName)")
                print("\(scenes.map({ $0.name }))")
                return
            }
            let index = Int(targetIndex!)
            
            fastRoom.view.whiteboardView.evaluateJavaScript("window.manager.setMainViewSceneIndex(\(index))")
            
            print("did setMainViewSceneIndex \(index)")
            
            for info in list {
                info.activityPage = item.id == info.id ? page : 0
                info.status = item.id == info.id ? .active : .inactive
            }
        })
        
    }
    
    func destoryWhiteBoard(path: String) {
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
                    switchWhiteBoard(path: changeToItem.name,
                                     page: 0)
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
}

extension BoardWapper {
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
        var activityPage: UInt
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
