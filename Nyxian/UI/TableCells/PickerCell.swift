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

class PickerTableCell: UITableViewCell {
    let title: String
    
    let options: [String]
    let key: String
    let defaultValue: Int
    var callback: (Int) -> Void = { _ in }
    
    let button: UIButton
    
    var value: Int {
        get {
            if UserDefaults.standard.object(forKey: self.key) == nil {
                UserDefaults.standard.set(self.defaultValue, forKey: self.key)
            }
            
            return UserDefaults.standard.integer(forKey: self.key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: self.key)
            callback(newValue)
        }
    }
    private var selectedOption: String {
        get {
            return self.options[self.value]
        }
        set {
            self.value = options.firstIndex(where: { $0 == newValue } ) ?? 0
        }
    }
    
    init(
        options: [String],
        title: String,
        key: String,
        defaultValue: Int
    ) {
        self.options = options
        self.title = title
        self.key = key
        self.defaultValue = defaultValue
        button = UIButton()
        super.init(style: .default, reuseIdentifier: nil)
        
        _ = self.value
        
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // disable selection
        self.selectionStyle = .none
        
        // First create the label
        let label: UILabel = UILabel()
        label.text = self.title
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        
        // create the chevron image
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let image: UIImage = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config)!
        
        // now the option button
        button.setTitle(self.selectedOption, for: .normal)
        button.setTitleColor(UILabel.appearance().textColor, for: .normal)
        button.setImage(image, for: .normal)
        
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        
        button.titleLabel?.textAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        button.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(button)
        
        // now the menu for the button
        refreshMenuItems()
        button.showsMenuAsPrimaryAction = true
        
        // Now fix its constraints
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            
            button.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func refreshMenuItems() {
        var menuItems: [UIMenuElement] = []
        for option in self.options {
            let index = self.options.firstIndex(where: { $0 == option } )
            menuItems.append(UIAction(title: "\(index ?? 0): \(option) \((self.selectedOption == option) ? "(Selected)" : "")") { _ in
                self.value = index ?? 0
                self.button.setTitle(self.selectedOption, for: .normal)
                self.refreshMenuItems()
            })
        }
        button.menu = UIMenu(children: menuItems)
    }
}
