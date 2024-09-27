//
//  TruncationExample.swift
//  AttributedText-Example
//
//  Created by Sun on 2024/9/27.
//

import UIKit

import SDWebImage
import SnapKit

import AttributedText

class TruncationExampleCell: UITableViewCell {
    
    typealias UpdateHandler = ((TruncationExampleCell, Int, Bool) -> Void)
    
    private let titleLabel = AttributedLabel()
    private let contentLabel = AttributedLabel()
    
    private var heightConstraint: Constraint?
    
    private var content: RowContent?
    private var index: Int?
    private var updateHandler: UpdateHandler?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(10)
        }
        
        contentLabel.isUserInteractionEnabled = true
        contentLabel.textVerticalAlignment = .top
        contentLabel.numberOfLines = 0
        contentLabel.setContentHuggingPriority(.required, for: .vertical)
        contentLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            self.heightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(10).priority(.high)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func updateCollapsed(_ content: RowContent) {
        let tokenText = "more"
        let text = NSMutableAttributedString(string: "...\(tokenText)")
        text.setFont(content.content.font)
            .setTextColor(content.content.textColor)
        let highlight = TextHighlight()
        highlight.color = UIColor(red: 0.578, green: 0.790, blue: 1.000, alpha: 1.000)
        highlight.tapAction = { [weak self] _, _, _, _ in
            guard let self, let index = self.index else { return }
            
            self.content?.isExpanded = true
            self.updateHandler?(self, index, true)
        }
        
        text.setTextColor(
            UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000),
            range: (text.string as NSString).range(of: tokenText)
        )
        .setTextHighlight(
            highlight,
            range: (text.string as NSString).range(of: tokenText)
        )
        
        let seeMore = AttributedLabel()
        seeMore.attributedText = text
        seeMore.sizeToFit()
        
        let truncationToken = NSAttributedString.attachmentString(
            content: seeMore,
            contentMode: .center,
            attachmentSize: seeMore.size,
            alignTo: text.font,
            alignment: .center
        )
        self.contentLabel.truncationToken = truncationToken
        self.contentLabel.attributedText = content.content
        self.updateContentHeight(content.content, isExpanded: content.isExpanded)
    }
    
    private func updateExpanded(_  content: RowContent) {
        let attributedText = NSMutableAttributedString(attributedString: content.content)
        
        let text = NSMutableAttributedString(string: "less")
        let highlight = TextHighlight()
        highlight.color = UIColor(red: 0.578, green: 0.790, blue: 1.000, alpha: 1.000)
        highlight.tapAction = { [weak self] _, _, _, _ in
            guard let self, let index = self.index else { return }
            
            self.content?.isExpanded = false
            self.updateHandler?(self, index, false)
        }
        
        text.setTextColor(UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000))
            .setTextHighlight(highlight)
            .setFont(content.content.font)
        
        let seeLess = AttributedLabel()
        seeLess.attributedText = text
        seeLess.sizeToFit()
        
        let truncationToken = NSAttributedString.attachmentString(
            content: seeLess,
            contentMode: .center,
            attachmentSize: seeLess.size,
            alignTo: attributedText.font,
            alignment: .center
        )
        
        attributedText.append(truncationToken)
        self.contentLabel.attributedText = attributedText
        self.updateContentHeight(attributedText, isExpanded: content.isExpanded)
    }
    
    private func updateContentHeight(_ content: NSAttributedString, isExpanded: Bool, animate: Bool = false) {
        let screenWidth = TextUtilities.screenSize.width - 40
        let maxHeight = CGFloat.greatestFiniteMagnitude
        let lineSpacing = content.lineSpacing
        
        let textContainerSize = CGSize(width: screenWidth, height: maxHeight)
        let textContainer = TextContainer(size: textContainerSize)
        textContainer.maximumNumberOfRows = 0
        
        if let textLayout = TextLayout(container: textContainer, text: content) {
            let lines = isExpanded ? textLayout.lines : Array(textLayout.lines.prefix(2))
            let totalHeight = lines.reduce(into: 0) { result, line in
                result += line.height + lineSpacing
            }
            self.heightConstraint?.update(offset: totalHeight)
        }
    }
    
    func update(_ content: RowContent, index: Int, updateHandler: UpdateHandler?) {
        titleLabel.text = content.title
        self.index = index
        self.content = content
        self.updateHandler = updateHandler
        
        if content.isExpanded {
            self.updateExpanded(content)
        } else {
            self.updateCollapsed(content)
        }
    }
    
    func updateHeight() {
        guard let content = self.content, let attributed = self.contentLabel.attributedText else {
            return
        }
        if content.isExpanded {
            self.updateExpanded(content)
        } else {
            self.updateCollapsed(content)
        }
        self.updateContentHeight(attributed, isExpanded: content.isExpanded, animate: true)
    }
}

struct RowContent {
    
    var title: String
    
    var isExpanded: Bool = false
    
    var content: NSAttributedString
}

class TruncationExample: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var contents: [RowContent] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let methodLabel = UILabel()
    
    private let methodSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.height.equalTo(40)
        }
        
        methodLabel.backgroundColor = .clear
        methodLabel.font = UIFont.systemFont(ofSize: 14)
        methodLabel.text = "Reload cell: "
        toolbar.addSubview(methodLabel)
        methodLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(10)
        }
        
        methodSwitch.layer.transformScale = 0.8
        toolbar.addSubview(methodSwitch)
        methodSwitch.addTarget(self, action: #selector(updateMethod), for: .touchUpInside)
        methodSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(methodLabel.snp.trailing).offset(10)
        }
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TruncationExampleCell.self, forCellReuseIdentifier: "TruncationExampleCell")
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        for index in 0..<20 {
            contents.append(RowContent(
                title: "Row: \(index)",
                content: self.attributedContent()
            ))
        }
    }
    
    @objc
    func updateMethod(_ sender: UISwitch) {
        methodLabel.text = sender.isOn ? "Just update cell height: " : "Reload cell: "
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "TruncationExampleCell",
            for: indexPath) as? TruncationExampleCell else {
            return UITableViewCell()
        }
        cell.update(contents[indexPath.row], index: indexPath.row) { [weak self] cell, _, isExpanded in
            guard let self else { return }
            
            self.updateCellHeight(cell, indexPath: indexPath, isExpanded: isExpanded)
        }
        return cell
    }
    
    private func updateCellHeight(_ cell: TruncationExampleCell, indexPath: IndexPath, isExpanded: Bool) {
        
        var newContent = self.contents[indexPath.row]
        guard newContent.isExpanded != isExpanded else {
            return
        }
        newContent.isExpanded = isExpanded
        self.contents[indexPath.row] = newContent
        self.tableView.performBatchUpdates { [weak self, weak cell] in
            guard let self, let cell else { return }
            
            if !self.methodSwitch.isOn {
                // 第1种方式: 刷新 cell
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            } else {
                // 第2种方式: 只更新 cell 高度
                cell.updateHeight()
            }
        }
    }
}

extension TruncationExample {
    
    private static let contentTemplates: [String] = [
        """
        It was the best of times, it was the worst of times, it was the age of wisdom, \
        it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, \
        it was the season of Light, it was the season of Darkness, it was the spring of hope, \
        it was the winter of despair, we had everything before us, we had nothing before us, \
        we were all going direct to Heaven, we were all going direct the other way--in short, \
        the period was so far like the present period that some of its noisiest authorities insisted \
        on its being received, for good or for evil, in the superlative degree of comparison only.\n
        """,
        """
        In ancient times the Rings of Power were crafted by the Elven-smiths, and Sauron, the Dark Lord, \
        forged the One Ring, filling it with his own power so that he could rule all others. \
        But the One Ring was taken from him, and though he sought it throughout Middle-earth, \
        it remained lost to him. After many ages it fell by chance into the hands of the hobbit Bilbo Baggins.
        """,
        """
        At a ball, the family is introduced to the Netherfield party, including Mr Bingley, \
        his two sisters and Mr Darcy, his dearest friend. Mr Bingley's friendly and cheerful manner earns him \
        popularity among the guests. He appears interested in Jane, the eldest Bennet daughter. \
        Mr Darcy, reputed to be twice as wealthy as Mr Bingley, is haughty and aloof, \
        causing a decided dislike of him. He declines to dance with Elizabeth, the second-eldest Bennet daughter, \
        as she is "not handsome enough". Although she jokes about it with her friend, \
        Elizabeth is deeply offended. Despite this first impression, Mr Darcy secretly begins to \
        find himself drawn to Elizabeth as they continue to encounter each other at social events, \
        appreciating her wit and frankness.
        """,
        """
        Twelve years later, after Isabella's death, the still-sickly Linton is brought back to live \
        with his uncle Edgar at the Grange, but Heathcliff insists that his son must instead live with him. \
        Cathy and Linton (respectively at the Grange and Wuthering Heights) gradually develop a relationship. \
        Heathcliff schemes to ensure that they marry, and on Edgar's death demands that the couple move in \
        with him. He becomes increasingly wild and reveals that on the night Catherine died he dug up her grave, \
        and ever since has been plagued by her ghost. When Linton dies, \
        Cathy has no option but to remain at Wuthering Heights.
        """,
        """
        In the months following Bonnie's death, Rhett is often drunk and disheveled, while Scarlett, \
        though equally bereaved, is more presentable. Melanie conceives a second child but loses the baby and \
        soon dies due to complications. As she comforts the widowed Ashley, Scarlett realizes she stopped loving \
        him long ago and perhaps she never did. She is shocked to realize that she has always loved Rhett, and \
        he has loved her in return. She returns home, brimming with her new love and determined to begin anew \
        with him. She discovers him packing his bags. In the wake of Melanie's death, Rhett has decided he wants \
        to rediscover the calm Southern dignity he once knew in his youth and is leaving Atlanta to find it. \
        Scarlett tries to persuade Rhett to either stay or take her with him, but he explains that while he \
        once loved Scarlett, the years of hurt and neglect have killed that love. He leaves and does not look back. \
        In the midst of her grief, Scarlett consoles herself with the knowledge that she still has Tara. \
        She plans to return there with the certainty that she can recover and win Rhett back, \
        because "tomorrow is another day."
        """,
        """
        The glass city is an image that comes to José Arcadio Buendía in a dream. It is the reason for \
        Macondo's location, but also a symbol of its fate. Higgins writes, "By the final page, however, \
        the city of mirrors has become a city of mirages. Macondo thus represents the dream of a \
        brave new world that America seemed to promise and that was cruelly proved illusory by the \
        subsequent course of history." Images such as the glass city and the ice factory represent \
        how Latin America already has its history outlined and is therefore fated for destruction.
        """,
        """
        Kostya is initially displeased that his return to his faith does not bring with it a complete \
        transformation to righteousness. However, at the end of the story, Kostya arrives at the conclusion \
        that despite his newly accepted beliefs, he is human and will go on making mistakes. His life can now \
        be meaningfully and truthfully oriented toward righteousness.
        """,
        """
        Mr. Brownlow has Monks arrested and forces him to divulge his secrets: he is actually Oliver's \
        half-brother and had hoped to steal Oliver's half of their rightful inheritance. Brownlow begs \
        Oliver to give half his inheritance to Monks and grant him a second chance, to which Oliver happily \
        agrees. Monks emigrates to America, but squanders his money, relapses into crime and dies in prison. \
        Fagin is arrested and sentenced to the gallows. The day before his execution, Oliver and Mr. \
        Brownlow visit him in Newgate Prison and learn the location of the documents proving Oliver's identity. \
        Bumble and his wife lose their jobs and are forced to become inmates of the workhouse. Rose Maylie, \
        who turns out to be Oliver's maternal aunt, marries and enjoys a long life. \
        Oliver lives happily with Mr. Brownlow as his adopted son.
        """
    ]
    
    private static let colorTemplates: [UIColor] = [
        UIColor(red: 0.890, green: 0.180, blue: 0.109, alpha: 0.250),
        UIColor(red: 0.678, green: 0.070, blue: 0.929, alpha: 0.300),
        UIColor(red: 0.686, green: 0.984, blue: 0.015, alpha: 0.150),
        UIColor(red: 0.686, green: 0.984, blue: 0.015, alpha: 0.150),
        UIColor(red: 0.964, green: 0.231, blue: 0.035, alpha: 0.200)
    ]
    
    private func attributedContent() -> NSAttributedString {
        
        guard let content = Self.contentTemplates.randomElement() else {
            return NSAttributedString(string: "")
        }
        let text = NSMutableAttributedString(string: content)
        let font = UIFont(name: "Noteworthy", size: 16)
        let shadow = TextShadow(
            color: Self.colorTemplates.randomElement(),
            offset: CGSize(width: 0, height: 2),
            radius: 2
        )
        text.setFont(font)
            .setLineSpacing(4)
            .setFirstLineHeadIndent(20)
            .setTextShadow(shadow)
        return text
    }
}
