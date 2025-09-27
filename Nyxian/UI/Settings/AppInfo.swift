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

// App
let buildName: String = "CottonCandy"
let buildStage: String = "Indev"
let buildVersion: Double = 0.6

// AppInfoView
class AppInfoViewController: UIThemedTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Info".localized
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : "Nyxian"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.section == 0) ? 120 : tableView.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "")
        
        if(indexPath.section == 0) {
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            
            let image: UIImage = UIImage(imageLiteralResourceName: "InfoThumbnail")
            let imageView: UIImageView = UIImageView(image: image)
            imageView.layer.cornerRadius = 15
            imageView.layer.masksToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            
            cell.contentView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.heightAnchor.constraint(equalToConstant: 100),
                imageView.widthAnchor.constraint(equalToConstant: 100),
                imageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                imageView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor)
            ])
        }else {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Name".localized
                cell.detailTextLabel?.text = buildName
            case 1:
                cell.textLabel?.text = "Version".localized
                cell.detailTextLabel?.text = String(buildVersion)
            default:
                cell.textLabel?.text = "Stage".localized
                cell.detailTextLabel?.text = buildStage
            }
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
}
