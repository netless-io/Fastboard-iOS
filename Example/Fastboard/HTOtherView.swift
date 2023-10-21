//
//  HTOtherView.swift
//  Fastboard_Example
//
//  Created by ZYP on 2023/10/21.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit


class HTOtherView: UIView, UITableViewDataSource, UITableViewDelegate {
    typealias Item = HTTableViewCell.Item
    let tableView = UITableView(frame: .zero, style: .plain)
    var dataList = [Item]()
    private weak var delegate: HTTableViewCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func commonInit() {
        tableView.register(HTTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func setDatas(list: [Item], delegate: HTTableViewCellDelegate) {
        self.delegate = delegate
        dataList = list
        tableView.reloadData()
    }
    
    func update(item: Item, indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HTTableViewCell
        cell.config(item: item)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HTTableViewCell
        cell.delegate = delegate
        let item = dataList[indexPath.row]
        cell.indexPath = indexPath
        cell.config(item: item)
        return cell
    }
}

enum HTAction {
    case last
    case next
    case share
    case unshare
}

protocol HTTableViewCellDelegate: NSObjectProtocol {
    func cellDidTap(index: IndexPath, action: HTAction, item: HTTableViewCell.Item)
}

class HTTableViewCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let pageLabel = UILabel()
    private let lastBtn = UIButton()
    private let nextBtn = UIButton()
    private let shareBtn = UIButton()
    var indexPath = IndexPath(row: 0, section: 0)
    private var item: Item!
    weak var delegate: HTTableViewCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(nameLabel)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private func setupUI() {
        pageLabel.textColor = .black
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastBtn)
        contentView.addSubview(pageLabel)
        contentView.addSubview(nextBtn)
        contentView.addSubview(shareBtn)
        
        nameLabel.textColor = .blue
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 5).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        lastBtn.setTitle("上一个", for: .normal)
        lastBtn.setTitleColor(.blue, for: .normal)
        lastBtn.translatesAutoresizingMaskIntoConstraints = false
        lastBtn.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 50).isActive = true
        lastBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.leftAnchor.constraint(equalTo: lastBtn.rightAnchor, constant: 5).isActive = true
        pageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        nextBtn.setTitle("下一个", for: .normal)
        nextBtn.setTitleColor(.blue, for: .normal)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.leftAnchor.constraint(equalTo: pageLabel.rightAnchor, constant: 15).isActive = true
        nextBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        shareBtn.setTitle("分享", for: .normal)
        shareBtn.setTitleColor(.blue, for: .normal)
        shareBtn.setTitle("移除", for: .selected)
        shareBtn.setTitleColor(.red, for: .selected)
        shareBtn.translatesAutoresizingMaskIntoConstraints = false
        shareBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        shareBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
    
    private func commonInit() {
        lastBtn.addTarget(self,
                          action: #selector(buttonTap(_:)),
                          for: .touchUpInside)
        nextBtn.addTarget(self,
                          action: #selector(buttonTap(_:)),
                          for: .touchUpInside)
        shareBtn.addTarget(self,
                          action: #selector(buttonTap(_:)),
                          for: .touchUpInside)
        
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == lastBtn {
            if item.currentPage == 0 {
                return
            }
            item.currentPage = item.currentPage - 1
            print("currentPage:\(item.currentPage)")
            delegate?.cellDidTap(index: indexPath, action: .last, item: item)
            config(item: item)
            return
        }
        if sender == nextBtn {
            if item.currentPage == item.pageCount - 1 {
                return
            }
            item.currentPage = item.currentPage + 1
            print("currentPage:\(item.currentPage)")
            delegate?.cellDidTap(index: indexPath, action: .next, item: item)
            config(item: item)
            return
        }
        if sender == shareBtn {
            item.isShare = !item.isShare
            delegate?.cellDidTap(index: indexPath, action: item.isShare ? .share : .unshare, item: item)
            shareBtn.isSelected = !shareBtn.isSelected
            return
        }
    }
    
    func config(item: Item) {
        self.item = item
        nameLabel.text = item.name
        pageLabel.text = "(\(item.currentPage)/\(item.pageCount))"
        shareBtn.isSelected = item.isShare
    }
    
}

extension HTTableViewCell {
    class Item {
        let name: String
        let pageCount: UInt
        var currentPage: UInt
        var isShare: Bool
        
        init(name: String, pageCount: UInt, currentPage: UInt, isShare: Bool) {
            self.name = name
            self.pageCount = pageCount
            self.currentPage = currentPage
            self.isShare = isShare
        }
    }
}
