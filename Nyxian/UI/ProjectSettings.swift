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

class ProjectSettingsViewController: UITableViewController {
    let project: NXProject
    
    let vtkey: [[(String, String, String)]]
    
    init(style: UITableView.Style,
         project: NXProject) {
        self.project = project
        self.vtkey = [
            [
                (self.project.projectConfig.displayName,"Display Name","LDEDisplayName"),
                (self.project.projectConfig.bundleid,"BundleID","LDEBundleIdentifier"),
                (self.project.projectConfig.version,"Version","LDEBundleVersion"),
                (self.project.projectConfig.shortVersion,"Short Version","LDEBundleShortVersion")
            ],
            [
                (self.project.projectConfig.executable,"Executable","LDEExecutable"),
                (self.project.projectConfig.platformMinimumVersion,"Minimum Deployments","LDEMinimumVersion")
            ]
        ]

        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ((section == 0) ? 1 : self.vtkey[section - 1].count)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Icon"
        case 1:
            return "Info"
        case 2:
            return "Build"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section != 0 {
            let cell: TextFieldTableCellHandler = TextFieldTableCellHandler(title: self.vtkey[indexPath.section - 1][indexPath.row].1, value: self.vtkey[indexPath.section - 1][indexPath.row].0)
            cell.writeHandler = { value in
                self.project.projectConfig.writeKey(self.vtkey[indexPath.section - 1][indexPath.row].2, withValue: value)
                //(self.project.tableCell as! NXProjectTableCell).reload()
            }
            return cell
        } else {
            let cell: UITableViewCell = UITableViewCell()
            cell.textLabel?.text = "S0n"
            return cell
        }
    }
}
