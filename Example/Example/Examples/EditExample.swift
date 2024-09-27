//
//  EditExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/28.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

import SDWebImage

class EditExample: UIViewController, AttributedTextViewDelegate, TextKeyboardObserver {
    
    private var textView = AttributedTextView()
    private var imageView: UIImageView?
    private var verticalSwitch = UISwitch()
    private var exclusionSwitch = UISwitch()
    private var textViewInsets = UIEdgeInsets.zero

    private var exclusionPathEnabled: Bool {
        get {
            return false
        }
        set {
            if newValue {
                if let imageView = imageView {
                    textView.addSubview(imageView)
                }
                let path = UIBezierPath(
                    roundedRect: imageView?.frame ?? .zero,
                    cornerRadius: imageView?.layer.cornerRadius ?? 0.0
                )
                textView.exclusionPaths = [path] // Set exclusion paths
            } else {
                imageView?.removeFromSuperview()
                textView.exclusionPaths = nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground

        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        initImageView()
        
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white
        toolbar.size = CGSize(width: TextUtilities.screenSize.width, height: 40)
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        toolbar.top = topBarHeight
        view.addSubview(toolbar)
        
        let text = NSMutableAttributedString(
            string: """
        It was the best of times, it was the worst of times, it was the age of wisdom, \
        it was the age of foolishness, it was the season of light, it was the season of darkness, \
        it was the spring of hope, it was the winter of despair, we had everything before us, \
        we had nothing before us. We were all going direct to heaven, \
        we were all going direct the other way. \
        \n\n
        这是最好的时代，这是最坏的时代；这是智慧的时代，这是愚蠢的时代；这是信仰的时期，这是怀疑的时期；\
        这是光明的季节，这是黑暗的季节；这是希望之春，这是失望之冬；人们面前有着各样事物，人们面前一无所有；\
        人们正在直登天堂，人们正在直下地狱。
        """
        )
        text.setFont(UIFont(name: "Times New Roman", size: 20))
        text.setLineSpacing(4)
        text.setFirstLineHeadIndent(20)
        
        textView.attributedText = text
        textView.size = view.size
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        textViewInsets = UIEdgeInsets(top: toolbar.bottom, left: 0, bottom: 0, right: 0)
        textView.contentInset = textViewInsets
        textView.scrollIndicatorInsets = textView.contentInset
        textView.selectedRange = NSRange(location: text.length, length: 0)
        view.insertSubview(textView, belowSubview: toolbar)
        
        let deadline = DispatchTime.now() + Double(Int64(0.6 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self else { return }
            self.textView.becomeFirstResponder()
        }
        
        var label: UILabel
        label = UILabel()
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Vertical:"
        // swiftlint:disable:next force_unwrapping
        label.size = CGSize(width: label.text!.width(for: label.font) + 2, height: toolbar.height)
        label.left = 10
        
        toolbar.addSubview(label)
        
        verticalSwitch.sizeToFit()
        verticalSwitch.centerY = toolbar.height / 2
        verticalSwitch.left = label.right - 5
        verticalSwitch.layer.transformScale = 0.8
        
        verticalSwitch.addBlock(forControlEvents: UIControl.Event.valueChanged, block: { [weak self] switcher in
            guard let self, let switcher = switcher as? UISwitch else {
                return
            }
            self.textView.endEditing(true)
            if switcher.isOn {
                self.exclusionPathEnabled = false
                self.exclusionSwitch.isOn = false
            }
            self.exclusionSwitch.isEnabled = !switcher.isOn
            self.textView.isVerticalForm = switcher.isOn // Set vertical form
        })
        toolbar.addSubview(verticalSwitch)
        
        label = UILabel()
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Exclusion:"
        // swiftlint:disable:next force_unwrapping
        label.size = CGSize(width: label.text!.width(for: label.font) + 2, height: toolbar.height)
        label.left = verticalSwitch.right + 5
        toolbar.addSubview(label)
        
        exclusionSwitch.sizeToFit()
        exclusionSwitch.centerY = toolbar.height / 2
        exclusionSwitch.left = label.right - 5
        exclusionSwitch.layer.transformScale = 0.8
        exclusionSwitch.addBlock(forControlEvents: UIControl.Event.valueChanged, block: { [weak self] switcher in
            guard let self else { return }
            // swiftlint:disable:next force_cast
            self.exclusionPathEnabled = (switcher as! UISwitch).isOn
        })
        toolbar.addSubview(exclusionSwitch)
        
        TextKeyboardManager.default.add(observer: self)
    }
    
    override func viewWillLayoutSubviews() {
        textView.size = view.size
    }
    
    private func initImageView() {
        guard let data = Data.dataNamed("dribbble256_imageio.png") else {
            return
        }
        
        let image = SDAnimatedImage(data: data, scale: 2)
        imageView = SDAnimatedImageView(image: image)
        
        imageView?.clipsToBounds = true
        imageView?.isUserInteractionEnabled = true
        // swiftlint:disable:next force_unwrapping
        imageView?.layer.cornerRadius = imageView!.height / 2.0
        imageView?.center = CGPoint(
            x: TextUtilities.screenSize.width / 2.0,
            y: TextUtilities.screenSize.width / 2.0
        )
        
        let gesture = UIPanGestureRecognizer(actionBlock: { [weak self] gesture in
            guard let self = self, let gesture = gesture as? UIPanGestureRecognizer else {
                return
            }
            
            let position = gesture.location(in: self.textView)
            self.imageView?.center = position
            let path = UIBezierPath(
                roundedRect: self.imageView?.frame ?? CGRect.zero,
                // swiftlint:disable:next force_unwrapping
                cornerRadius: self.imageView!.layer.cornerRadius
            )
            self.textView.exclusionPaths = [path]
        })
        imageView?.addGestureRecognizer(gesture)
    }
    
    @objc
    private func edit(_ item: UIBarButtonItem?) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    // MARK: - AttributedTextViewDelegate
    
    func textViewDidBeginEditing(_ textView: AttributedTextView) {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.edit(_:)))
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    func textViewDidEndEditing(_ textView: AttributedTextView) {
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: - keyboard
    
    func keyboardChanged(with transition: TextKeyboardTransition) {
        var clipped = false
        if textView.isVerticalForm && transition.toVisible {
            let rect = TextKeyboardManager.default.convert(transition.toFrame, to: view)
            if rect.maxY == view.height {
                var textFrame: CGRect = view.bounds
                textFrame.size.height -= rect.size.height
                textView.frame = textFrame
                clipped = true
            }
        }
        
        if !clipped {
            textView.frame = view.bounds
        }
        textView.contentInset = textViewInsets
    }
}
