//
//  AttributedTextAsyncExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

import SDWebImage
import SnapKit

private var kAsyncExampleCellId = "kAsyncExampleCellId"
private let kCellHeight: CGFloat = 140

class TextAsyncExampleCell: UITableViewCell {
    
    private var uiLabel = UILabel()
    private var asyncLabel = AttributedLabel()
    
    var async: Bool = false {
        didSet {
            if async == oldValue {
                return
            }
            uiLabel.isHidden = async
            asyncLabel.isHidden = !async
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        uiLabel.font = UIFont.systemFont(ofSize: 8)
        uiLabel.numberOfLines = 0
        uiLabel.size = CGSize(width: TextUtilities.screenSize.width, height: CGFloat(kCellHeight))
        
        asyncLabel.font = uiLabel.font
        asyncLabel.numberOfLines = uiLabel.numberOfLines
        asyncLabel.size = uiLabel.size
        asyncLabel.isDisplaysAsynchronously = true // enable async display
        asyncLabel.isHidden = true
        
        contentView.addSubview(uiLabel)
        contentView.addSubview(asyncLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setAyncText(_ text: Any) {
        if async {
            asyncLabel.layer.contents = nil
            asyncLabel.textLayout = text as? TextLayout
        } else {
            uiLabel.attributedText = text as? NSAttributedString
        }
    }
}

class AsyncExample: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var isAsync = false {
        didSet {
            for cell in tableView.visibleCells {
                guard let cell = cell as? TextAsyncExampleCell else {
                    return
                }
                cell.async = isAsync
                
                if let indexPath = self.tableView.indexPath(for: cell) {
                    if self.isAsync {
                        cell.setAyncText(self.layouts[indexPath.row])
                    } else {
                        cell.setAyncText(self.strings[indexPath.row])
                    }
                }
            }
            asyncLabel.text = isAsync ? "AttributedLabel(Async)" : "UILabel(Sync)"
            asyncLabel.textColor = isAsync ? .systemGreen : .black
        }
    }
    private var strings: [NSMutableAttributedString] = []
    private var layouts: [TextLayout] = []
    private var tableView = UITableView()
    
    private let asyncLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TextAsyncExampleCell.self, forCellReuseIdentifier: kAsyncExampleCellId)
        var newInsets = tableView.contentInset
        newInsets.top += 40
        tableView.contentInset = newInsets
        var newIndicatorInsets = tableView.verticalScrollIndicatorInsets
        newIndicatorInsets.top += 40
        tableView.verticalScrollIndicatorInsets = newIndicatorInsets
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        for index in 0..<50 {
            let str = """
            \(index) \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 ◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 \
            😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ \
            Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 \
            😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 
            """
            
            let font = UIFont.systemFont(ofSize: 10)
            let text = NSMutableAttributedString(string: str)
            text.setFont(font)
                .setLineSpacing(0)
                .setStrokeWidth(-3)
                .setStrokeColor(UIColor.red)
                .setLineHeightMultiple(1)
                .setMaximumLineHeight(12)
                .setMinimumLineHeight(12)
            
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 1
            shadow.shadowColor = UIColor.red
            shadow.shadowOffset = CGSize(width: 0, height: 1)
            self.strings.append(text)
            
            // it better to do layout in background queue...
            let container = TextContainer(size: CGSize(
                width: TextUtilities.screenSize.width,
                height: kCellHeight)
            )
            if let layout = TextLayout(container: container, text: text) {
                self.layouts.append(layout)
            }
        }
        
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        
        asyncLabel.backgroundColor = UIColor.clear
        asyncLabel.text = "UILabel(Sync): "
        asyncLabel.font = UIFont.systemFont(ofSize: 14)
        toolbar.addSubview(asyncLabel)
        asyncLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        
        let switcher = UISwitch()
        switcher.layer.transformScale = 0.7
        switcher.addBlock(forControlEvents: UIControl.Event.valueChanged, block: { [weak self] switcher in
            guard let self, let switcher = switcher as? UISwitch else {
                return
            }
            self.isAsync = switcher.isOn
        })
        
        toolbar.addSubview(switcher)
        switcher.snp.makeConstraints { make in
            make.leading.equalTo(asyncLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strings.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kCellHeight
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: kAsyncExampleCellId, for: indexPath) as! TextAsyncExampleCell
        
        cell.async = isAsync
        if isAsync {
            cell.setAyncText(layouts[indexPath.row])
        } else {
            cell.setAyncText(strings[indexPath.row])
        }
        
        return cell
    }
}
