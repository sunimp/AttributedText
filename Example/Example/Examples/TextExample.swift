//
//  TextExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

class TextExample: UITableViewController {

    private var titles: [String] = []
    private var classNames: [UIViewController.Type] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        APMWindow.show()
        
        title = "✎      Examples      ✎"
        
        addCell("Text Attributes 1", class: AttributeExample.self)
        addCell("Text Attributes 2", class: TagExample.self)
        addCell("Text Attachments", class: AttachmentExample.self)
        addCell("Text Truncations", class: TruncationExample.self)
        addCell("Text Edit", class: EditExample.self)
        addCell("Text Parser (Markdown)", class: MarkdownExample.self)
        addCell("Text Parser (Emoticon)", class: EmoticonExample.self)
        addCell("Text Binding", class: BindingExample.self)
        addCell("Copy and Paste", class: CopyPasteExample.self)
        addCell("Undo and Redo", class: UndoRedoExample.self)
        addCell("Ruby Annotation", class: RubyExample.self)
        addCell("Async Display", class: AsyncExample.self)
        
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        
        tableView.reloadData()
    }
    
    func addCell(_ title: String, class: UIViewController.Type) {
        titles.append(title)
        classNames.append(`class`)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") else {
            fatalError("have not register cell class")
        }
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cls = classNames[indexPath.row]
        let ctrl = cls.init()
        
        ctrl.title = titles[indexPath.row]
        navigationController?.pushViewController(ctrl, animated: true)
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
