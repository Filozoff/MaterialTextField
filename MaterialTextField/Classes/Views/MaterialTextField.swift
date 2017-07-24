//
//  MaterialTextField.swift
//  MaterialTextField
//
//  Created by Kamil Wyszomierski on 24/07/2017.
//  Copyright © 2017 Kamil Wyszomierski. All rights reserved.
//

import UIKit

@IBDesignable
class MaterialTextField: UITextField {
        
    // MARK: - Properties
    
    let floatingLabel = UILabel()
    
    fileprivate let bottomLine = CALayer()
    
    private var floatingTopConstraint: NSLayoutConstraint?
    private let lineVerticalSpacing: CGFloat = 2
    private let textVerticalSpacing: CGFloat = 4
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    private func commonInit() {
        self.addNotifications()
        
        self.layer.addSublayer(self.bottomLine)
        
        self.floatingLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        self.floatingLabel.textColor = .lightGray
        self.floatingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.floatingLabel)
        
        self.updateFrames()
        self.updateView()
        
        self.setNeedsUpdateConstraints()
    }
    
    deinit {
        self.removeNotifications()
    }
    
    // MARK: - Observers
    
    private func addNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBeginEditing(notification:)), name: .UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChange(notification:)), name: .UITextFieldTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEndEditing(notification:)), name: .UITextFieldTextDidEndEditing, object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidEndEditing, object: nil)
    }
    
    // MARK: - Updates
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if super.attributedPlaceholder != nil {
            self.attributedPlaceholder = super.attributedPlaceholder
        }
        
        if super.placeholder != nil {
            self.placeholder = super.placeholder
        }
        
        self.updateFrames()
        self.updateView()
        self.updateOnTextChange()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateFrames()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        self.updateColors(animated: false)
    }
    
    override func updateConstraints() {
        self.floatingTopConstraint = self.floatingLabel.topAnchor.constraint(equalTo: self.topAnchor)
        self.floatingTopConstraint?.isActive = true
        self.floatingLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.floatingLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.floatingLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1).isActive = true
        
        super.updateConstraints()
    }
    
    private func updateFrames() {
        self.bottomLine.frame = CGRect(x: 0, y: self.bounds.height - 1, width: self.bounds.width, height: 1)
    }
    
    private func updateView() {
        self.font = super.font
        
        if self.placeholder != nil {
            self.floatingLabel.text = self.placeholder
        }
        else if self.attributedPlaceholder != nil {
            self.floatingLabel.attributedText = self.attributedPlaceholder
        }
        
        self.updateColors(animated: false)
    }
    
    fileprivate func updateOnTextChange(animated isAnimated: Bool = false) {
        let shouldReveal = self.shouldReveal()
        self.setPlaceholderMovedUp(shouldReveal, animated: isAnimated)
    }
    
    fileprivate func updateColors(animated isAnimated: Bool) {
        let shouldReveal = self.shouldReveal()
        let stateTintColor = self.isEnabled ? self.tintColor : UIColor.lightGray.withAlphaComponent(0.8)
        let revealStateControlColor = shouldReveal ? self.tintColor : self.textColor
        let colorForCurrentState = self.isEnabled ? revealStateControlColor : UIColor.lightGray.withAlphaComponent(0.8)
        self.bottomLine.backgroundColor = stateTintColor?.cgColor
        
        if !isAnimated {
            self.floatingLabel.textColor = colorForCurrentState
            return
        }
        
        // Because property `textColor` isn't animatable, textField's color change is done using transition.
        UIView.transition(with: self.floatingLabel, duration: .animationDefault, options: .transitionCrossDissolve, animations: { [weak self] () in
            self?.floatingLabel.textColor = colorForCurrentState
        }, completion: nil)
    }
    
    // MARK: - Actions
    
    @objc private func didBeginEditing(notification: Notification) {
        if !self.isNotificationObjectCurrentObject(notification.object) {
            return
        }
        
        self.updateOnTextChange(animated: true)
    }
    
    @objc private func didChange(notification: Notification) {
        if !self.isNotificationObjectCurrentObject(notification.object) {
            return
        }
        
        // TODO:
    }
    
    @objc private func didEndEditing(notification: Notification) {
        if !self.isNotificationObjectCurrentObject(notification.object) {
            return
        }
        
        self.updateOnTextChange(animated: true)
    }
    
    // MARK: - Animations
    
    private func setPlaceholderMovedUp(_ isMovedUp: Bool, animated: Bool) {
        let translationY = self.estimatedLineHeight
        let translationX = self.bounds.width * (1 - self.calculatedScale) / 2
        let movedUpTransform = CGAffineTransform(
            a: self.calculatedScale,
            b: 0,
            c: 0,
            d: self.calculatedScale,
            tx: -translationX,
            ty: -translationY
        )
        let transform: CGAffineTransform = isMovedUp ? movedUpTransform : .identity
        
        self.layoutIfNeeded()
        
        if !animated {
            self.floatingLabel.transform = transform
            self.updateColors(animated: animated)
            return
        }
        
        UIView.animate(withDuration: .animationDefault, animations: { [weak self] () in
            self?.floatingLabel.transform = transform
        }, completion: { [weak self] (finished) in
            self?.updateColors(animated: animated)
        })
    }
    
    // MARK: - Padding
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let posY = self.estimatedLineHeight * 0.25 + self.textVerticalSpacing - self.lineVerticalSpacing
        self.floatingTopConstraint?.constant = posY
        var rect = super.editingRect(forBounds: bounds)
        rect.origin.y = rect.origin.y + posY
        
        return rect
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let posY = self.estimatedLineHeight * 0.25 + self.textVerticalSpacing - self.lineVerticalSpacing
        self.floatingTopConstraint?.constant = posY
        var rect = super.textRect(forBounds: bounds)
        rect.origin.y = rect.origin.y + posY
        
        return rect
    }
    
    // MARK: - Helpers
    
    private func isNotificationObjectCurrentObject(_ object: Any?) -> Bool {
        guard let textField = object as? MaterialTextField else {
            return false
        }
        
        return textField == self
    }
    
    private func shouldReveal() -> Bool {
        let string = super.text ?? super.attributedText?.string
        let numberOfCharacters = string?.characters.count ?? 0
        let hasText = numberOfCharacters > 0
        return hasText || self.isEditing
    }
    
    // MARK: - Getters / setters
    
    override var attributedPlaceholder: NSAttributedString? {
        get {
            return self.floatingLabel.attributedText
        }
        set {
            super.attributedPlaceholder = nil
            self.floatingLabel.attributedText = newValue
        }
    }
    
    /// `borderStyle` is always `UITextBorderStyle.none`.
    override final var borderStyle: UITextBorderStyle {
        get {
            return .none
        }
        set {
            super.borderStyle = .none
        }
    }
    
    private var calculatedPlaceholderFontSize: CGFloat {
        return log2(self.defaultFontSize) * .pi
    }
    
    private var calculatedScale: CGFloat {
        return self.calculatedPlaceholderFontSize / self.defaultFontSize
    }
    
    private var defaultFontSize: CGFloat {
        return self.font?.pointSize ?? UIFont.systemFontSize
    }
    
    private var estimatedLineHeight: CGFloat {
        return self.defaultFontSize * 1.2
    }
    
    override var font: UIFont? {
        didSet {
            self.floatingLabel.font = self.font
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = self.estimatedLineHeight * 2 + self.textVerticalSpacing + self.lineVerticalSpacing + self.bottomLine.frame.height
        
        return size
    }
    
    override var placeholder: String? {
        get {
            return self.floatingLabel.text
        }
        set {
            super.placeholder = nil
            self.floatingLabel.text = newValue
        }
    }
    
    override var textAlignment: NSTextAlignment {
        didSet {
            self.floatingLabel.textAlignment = self.textAlignment
        }
    }
}
