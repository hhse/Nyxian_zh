/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation
import UIKit
import Runestone
@testable import Runestone

// MARK: - COORDINATOR
class Coordinator: NSObject, TextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    private weak var parent: CodeEditorViewController?
    private var entries: [UInt64:(NeoButton?,UIView?)] = [:]
    
    private var autocompleteDropdown: UITableView?
    private var currentAutocompletes: [String] = []
    
    private(set) var isProcessing: Bool = false
    private(set) var isInvalidated: Bool = false
    private(set) var needsAnotherProcess: Bool = false

    private var debounce: Debouncer?
    private(set) var diag: [Synitem] = []
    private let vtkey: [(String,UIColor)] = [
        ("info.circle.fill", UIColor.blue.withAlphaComponent(0.3)),
        ("exclamationmark.triangle.fill", UIColor.orange.withAlphaComponent(0.3)),
        ("xmark.octagon.fill", UIColor.red.withAlphaComponent(0.3))
    ]
    
    init(parent: CodeEditorViewController) {
        self.parent = parent
        super.init()
        guard self.parent?.synpushServer != nil else { return }
        self.debounce = Debouncer(delay: 1.5) { [weak self] in
            guard let self = self else { return }
            self.isProcessing = true
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                self.parent?.synpushServer?.reparseFile(self.parent?.textView.text)
                self.diag = self.parent?.synpushServer?.getDiagnostics() ?? []
                self.updateDiag()
            }
        }
        if let textView = self.parent?.textView {
            self.textViewDidChange(textView)
        }
    }
    
    func textViewDidChange(_ textView: TextView) {
        guard self.parent?.synpushServer != nil else { return }
        if !self.isInvalidated {
            self.isInvalidated = true
            for item in self.entries {
                UIView.animate(withDuration: 0.3) {
                    item.value.1!.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
                    item.value.0!.backgroundColor = UIColor.systemGray.withAlphaComponent(1.0)
                    item.value.0!.isUserInteractionEnabled = false
                    item.value.0!.errorview?.alpha = 0.0
                } completion: { _ in
                    item.value.0!.errorview?.removeFromSuperview()
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.redrawDiag()
        }
        
        if self.isProcessing {
            self.needsAnotherProcess = true
            return
        }
        
        self.debounce?.debounce()
    }
    
    func textViewDidChangeSelection(_ textView: TextView) {
        if self.isInvalidated {
            self.debounce?.debounce()
        }
        
        
        if(self.parent?.project?.codeEditorConfig.autocompletion ?? false) {
            updateAutocomplete()
        }
    }
    
    func redrawDiag() {
        guard let parent = self.parent else { return }
        
        /*if let textView = self.parent?.textView,
           let selectedRange: UITextRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let utf16View = textView.text.utf16
            let endIndex = utf16View.index(utf16View.startIndex, offsetBy: cursorPosition)
            if let textUpToCursor = String(utf16View[..<endIndex]) {
                let lines: [String] = textUpToCursor.components(separatedBy: "\n")
                if let currentLine: String = lines.last {
                    let line = lines.count
                    let column = currentLine.count + 1
                    
                    self.parent?.synpushServer?.reparseFile(textView.text)
                    if let autocompletes: [String] = self.parent?.synpushServer?.getAutocompletionsAtLine(UInt32(line), atColumn: UInt32(column)) {
                        print("\(line) \(column) \(autocompletes)")
                    }
                }
            }
        }*/
        
        if !self.entries.isEmpty {
            for item in self.entries {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard let rect = parent.textView.rectForLine(Int(item.key)) else {
                        UIView.animate(withDuration: 0.3, animations: {
                            item.value.0?.alpha = 0
                            item.value.1?.alpha = 0
                        }, completion: { _ in
                            item.value.0?.removeFromSuperview()
                            item.value.1?.removeFromSuperview()
                            self.entries.removeValue(forKey: item.key)
                        })
                        return
                    }
                    item.value.0?.frame = CGRect(x: 0, y: rect.origin.y, width: parent.textView.gutterWidth, height: rect.height)
                    item.value.1?.frame = CGRect(x: 0, y: rect.origin.y, width: parent.textView.bounds.size.width, height: rect.height)
                }
            }
        }
    }
    
    func updateDiag() {
        guard let parent = self.parent else { return }
        if !self.entries.isEmpty {
            let waitonmebaby: DispatchSemaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    for item in self.entries {
                        item.value.0?.alpha = 0
                        item.value.1?.alpha = 0
                    }
                }, completion: { _ in
                    for item in self.entries {
                        item.value.0?.removeFromSuperview()
                        item.value.1?.removeFromSuperview()
                    }
                    self.entries.removeAll()
                    waitonmebaby.signal()
                })
            }
            waitonmebaby.wait()
        }
        
        for item in diag {
            guard self.entries[item.line] == nil else { continue }
            self.entries[item.line] = (nil, nil)
            
            var rect: CGRect?
            DispatchQueue.main.sync {
                rect = parent.textView.rectForLine(Int(item.line))
            }
            guard let rect = rect else { continue }
            
            let properties: (String,UIColor) = self.vtkey[Int(item.type)]
            
            DispatchQueue.main.async {
                let view: UIView = UIView(frame: CGRect(x: 0, y: rect.origin.y, width: parent.textView.bounds.size.width, height: rect.height))
                view.backgroundColor = properties.1
                view.isUserInteractionEnabled = false
                
                let button = NeoButton(frame: CGRect(x: 0, y: rect.origin.y, width: parent.textView.gutterWidth, height: rect.height))
                
                button.backgroundColor = properties.1.withAlphaComponent(1.0)
                let configuration: UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(pointSize: parent.textView.theme.lineNumberFont.pointSize)
                let image = UIImage(systemName: properties.0, withConfiguration: configuration)
                button.setImage(image, for: .normal)
                button.imageView?.tintColor = UIColor.systemBackground
                
                var widthConstraint: NSLayoutConstraint?
                
                button.setAction { [weak self, weak button, weak parent] in
                    guard let self = self, let button = button, let parent = parent else{ return }
                    button.stateview = !button.stateview
                    
                    if button.stateview {
                        DispatchQueue.main.async {
                            let shift: CGFloat = parent.textView.gutterWidth
                            let finalWidth = (parent.textView.bounds.width) / 1.5
                            
                            let modHeight = rect.height + 10
                            
                            let preview = ErrorPreview(
                                parent: self,
                                frame: CGRect.zero,
                                message: item.message,
                                color: properties.1,
                                minH: modHeight
                            )
                            preview.translatesAutoresizingMaskIntoConstraints = false
                            button.errorview = preview
                            
                            preview.alpha = 0
                            
                            if let textView = self.parent?.textView {
                                textView.addSubview(preview)
                                
                                widthConstraint = preview.widthAnchor.constraint(equalToConstant: 0)
                                NSLayoutConstraint.activate([
                                    preview.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: shift),
                                    preview.topAnchor.constraint(equalTo: textView.topAnchor, constant: rect.origin.y),
                                    widthConstraint!
                                ])
                                
                                textView.layoutIfNeeded()
                                
                                UIView.animate(
                                    withDuration: 0.5,
                                    delay: 0,
                                    usingSpringWithDamping: 0.8,
                                    initialSpringVelocity: 0.5,
                                    options: [.curveEaseOut],
                                    animations: {
                                        preview.alpha = 1
                                        widthConstraint!.constant = finalWidth
                                        textView.layoutIfNeeded()
                                    },
                                    completion: nil
                                )
                            }
                        }
                    } else {
                        if let preview = button.errorview {
                            DispatchQueue.main.async {
                                UIView.animate(
                                    withDuration: 0.3,
                                    delay: 0,
                                    options: [.curveEaseIn],
                                    animations: {
                                        preview.alpha = 0
                                        widthConstraint!.constant = 0
                                        preview.superview?.layoutIfNeeded()
                                    },
                                    completion: { _ in
                                        preview.removeFromSuperview()
                                    }
                                )
                            }
                        }
                    }
                }
                
                view.alpha = 0
                button.alpha = 0
                self.entries[item.line] = (button,view)
                
                if let textInputView = parent.textView.getTextInputView() {
                    textInputView.addSubview(view)
                    textInputView.sendSubviewToBack(view)
                    textInputView.gutterContainerView.isUserInteractionEnabled = true
                    textInputView.gutterContainerView.addSubview(button)
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    view.alpha = 1
                    button.alpha = 1
                }, completion: { _ in
                    button.isUserInteractionEnabled = true
                })
                
            }
        }
        
        DispatchQueue.main.async {
            self.isProcessing = false
            self.isInvalidated = false
            
            if self.needsAnotherProcess,
               let textView = self.parent?.textView {
                self.needsAnotherProcess = false
                self.textViewDidChange(textView)
            }
        }
    }
    
    private func showAutocompletes(_ autocompletes: [String], at rect: CGRect) {
        guard let parent = self.parent, !autocompletes.isEmpty else { return }

        // Remove old dropdown if exists
        autocompleteDropdown?.removeFromSuperview()

        currentAutocompletes = autocompletes

        let dropdown = UITableView()
        dropdown.tag = 999
        dropdown.layer.borderColor = UIColor.gray.cgColor
        dropdown.layer.borderWidth = 1
        dropdown.layer.cornerRadius = 5
        dropdown.isScrollEnabled = true
        dropdown.rowHeight = 24
        dropdown.dataSource = self
        dropdown.delegate = self
        dropdown.backgroundColor = UIColor.systemBackground

        let width: CGFloat = 200
        let maxHeight: CGFloat = 150
        dropdown.frame = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + rect.height,
            width: width,
            height: min(maxHeight, CGFloat(autocompletes.count * Int(dropdown.rowHeight)))
        )

        parent.view.addSubview(dropdown)
        autocompleteDropdown = dropdown
        dropdown.reloadData()
    }
    
    func updateAutocomplete() {
        guard let textView = self.parent?.textView,
              let selectedRange = textView.selectedTextRange else {
            autocompleteDropdown?.removeFromSuperview()
            return
        }

        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let utf16View = textView.text.utf16
        let endIndex = utf16View.index(utf16View.startIndex, offsetBy: cursorPosition)
        guard let textUpToCursor = String(utf16View[..<endIndex]) else {
            autocompleteDropdown?.removeFromSuperview()
            return
        }

        let lines = textUpToCursor.components(separatedBy: "\n")
        let lineNumber = lines.count
        let currentLine = lines.last ?? ""
        let column = currentLine.count + 1

        // Request completions
        parent?.synpushServer?.updateBuffer(textView.text)
        guard let completions = parent?.synpushServer?.getAutocompletionsAtLine(UInt32(lineNumber), atColumn: UInt32(column)),
              !completions.isEmpty else {
            autocompleteDropdown?.removeFromSuperview()
            return
        }

        // Show dropdown at caret
        let caretRect = textView.caretRect(for: selectedRange.start)
        let dropdownRect = textView.convert(caretRect, to: parent?.view)
        showAutocompletes(completions, at: dropdownRect)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return currentAutocompletes.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell()
            cell.textLabel?.text = currentAutocompletes[indexPath.row]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
            return cell
        }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let textView = parent?.textView,
              let sel = textView.selectedTextRange else { return }

        let completion = currentAutocompletes[indexPath.row]

        let caret = sel.end
        if textView.offset(from: sel.start, to: sel.end) != 0,
           let collapsed = textView.textRange(from: caret, to: caret) {
            textView.selectedTextRange = collapsed
        }

        guard let cursorRange = textView.selectedTextRange else { return }

        var start = cursorRange.start
        let underscore = "_".unicodeScalars.first!
        while let prev = textView.position(from: start, offset: -1),
              let r = textView.textRange(from: prev, to: start),
              let s = textView.text(in: r),
              let scalar = s.unicodeScalars.first,
              CharacterSet.alphanumerics.contains(scalar) || scalar == underscore {
            start = prev
        }

        let prefixRange = textView.textRange(from: start, to: cursorRange.start)
        let typed = prefixRange.flatMap { textView.text(in: $0) } ?? ""

        let suffix = completion.hasPrefix(typed) ? String(completion.dropFirst(typed.count)) : completion
        textView.replace(cursorRange, withText: suffix)

        tableView.removeFromSuperview()
    }

    
    class ErrorPreview: UIView {
        var textView: UITextView
        var heigth: CGFloat = 0.0

        init(parent: Coordinator, frame: CGRect, message: String, color: UIColor, minH: CGFloat) {
            textView = UITextView()
            super.init(frame: .zero)

            self.backgroundColor = parent.parent?.textView.theme.gutterBackgroundColor
            self.layer.borderColor = color.withAlphaComponent(1.0).cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 10
            self.layer.maskedCorners = [
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner,
                .layerMinXMaxYCorner
            ]

            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.text = message
            textView.font = parent.parent?.textView.theme.font
            textView.font = textView.font?.withSize((textView.font?.pointSize ?? 10) / 1.25)
            textView.textColor = UIColor.label
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.textContainerInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)

            self.addSubview(textView)

            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
                textView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
                textView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                textView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                self.heightAnchor.constraint(greaterThanOrEqualToConstant: minH)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class NeoButton: UIButton {
        var actionTap: () -> Void
        var stateview: Bool = false
        var errorview: ErrorPreview? = nil
        
        let hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        
        override init(frame: CGRect) {
            self.actionTap = {}
            super.init(frame: frame)
            self.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                self.actionTap()
            }, for: UIControl.Event.touchDown)
        }
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let relativeFrame = self.bounds
            let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
            return hitFrame.contains(point)
        }
        
        func setAction(action: @escaping () -> Void) {
            self.actionTap = action
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func willMove(toSuperview newSuperview: UIView?) {
            if newSuperview == nil {
                if self.stateview {
                    actionTap()
                }
            }
            super.willMove(toSuperview: newSuperview)
        }
    }
    
    class Debouncer {
        private var workItem: DispatchWorkItem?
        private let queue: DispatchQueue
        private let delay: TimeInterval
        private let action: () -> Void

        init(delay: TimeInterval,
             queue: DispatchQueue = .main,
             action: @escaping () -> Void) {
            self.delay = delay
            self.queue = queue
            self.action = action
        }

        func debounce() {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: action)
            if let workItem = workItem {
                queue.asyncAfter(deadline: .now() + delay, execute: workItem)
            }
        }
    }
}

// MARK: - Test
extension Runestone.TextView {
    func rectForLine(_ lineNumber: Int) -> CGRect? {
        let mirror = Mirror(reflecting: self)
        guard let lmAny = mirror.descendant("textInputView", "layoutManager"),
              let layoutManager = lmAny as? LayoutManager
        else {
            return nil
        }
        
        let lmMirror = Mirror(reflecting: layoutManager)
        guard let lineManager = lmMirror.descendant("lineManager") as? LineManager
        else {
            return nil
        }
        
        let index = lineNumber - 1
        guard index >= 0,
              index < lineManager.lineCount
        else {
            return nil
        }
        
        let targetLine = lineManager.line(atRow: lineNumber - 1)
        let endOffset = targetLine.location + targetLine.data.length
        layoutManager.layoutLines(toLocation: endOffset)
        
        let line = lineManager.line(atRow: index)
        
        let minY = line.yPosition
        let height = line.data.lineHeight
        let inset = layoutManager.textContainerInset
        let width = layoutManager.scrollViewWidth
        
        return CGRect(x: 0,
                      y: inset.top + minY,
                      width: width,
                      height: height)
    }
    
    func getTextInputView() -> TextInputView? {
        let mirror = Mirror(reflecting: self)
        guard let tiview = mirror.descendant("textInputView"),
              let textInputView = tiview as? TextInputView
        else {
            return nil
        }
        
        return textInputView
    }
}
