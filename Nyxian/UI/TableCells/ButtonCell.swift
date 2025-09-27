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

import UIKit

class ButtonTableCell: UITableViewCell {
    let title: String
    var button: UIButton?
    
    init(
        title: String
    ) {
        self.title = title
        super.init(style: .default, reuseIdentifier: nil)
        
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Setting up the button
        button = UIButton()
        button?.titleLabel?.textAlignment = .left
        button?.contentHorizontalAlignment = .left
        button?.setTitle(self.title, for: .normal)
        button?.setTitleColor(UILabel.appearance().textColor, for: .normal)
        button?.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(button!)
        
        // Now fix its constraints
        NSLayoutConstraint.activate([
            button!.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            button!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            button!.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            button!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16)
        ])
    }
}
