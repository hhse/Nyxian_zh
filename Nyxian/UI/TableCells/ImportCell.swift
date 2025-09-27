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
import UniformTypeIdentifiers

class ImportTableCell: UITableViewCell, UIDocumentPickerDelegate {
    private weak var parent: UIViewController?
    private var button: UIButton?
    private var label: UILabel?
    private(set) var url: URL?
    
    init(
        parent: UIViewController,
    ) {
        super.init(style: .default, reuseIdentifier: nil)
        self.parent = parent
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Setup the button
        self.button = UIButton()
        self.button?.titleLabel?.textAlignment = .left
        self.button?.contentHorizontalAlignment = .left
        self.button?.setTitle("Import", for: .normal)
        self.button?.setTitleColor(UIColor.systemBlue, for: .normal)
        self.button?.translatesAutoresizingMaskIntoConstraints = false
        self.button?.addAction(UIAction { [weak self] _ in
            guard let self = self,
            let parent = self.parent else { return }
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = .formSheet
            parent.present(documentPicker, animated: true)
        }, for: .touchUpInside)
        self.contentView.addSubview(self.button!)

        // Setup the label
        self.label = UILabel()
        self.label!.translatesAutoresizingMaskIntoConstraints = false
        self.button!.addSubview(self.label!)

        // Constraints
        NSLayoutConstraint.activate([
            self.button!.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.button!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.button!.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.button!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),

            self.label!.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.label!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16)
        ])
        
        self.label!.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        self.url = selectedURL
        
        print("Picked file: \(selectedURL.lastPathComponent)")
        
        UIView.animate(withDuration: 0.25) {
            self.label!.alpha = 0.0
        } completion: { [weak self ]_ in
            guard let self = self else { return }
            self.label!.text = selectedURL.lastPathComponent
            
            UIView.animate(withDuration: 0.25) {
                self.label!.alpha = 1.0
            }
        }
    }
}
