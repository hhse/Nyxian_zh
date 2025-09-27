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
import UniformTypeIdentifiers

class CertificateImporter: UIThemedTableViewController, UITextFieldDelegate {
    var textField: UITextField?
    
    var cert: ImportTableCell?
    
    let sectionTitles: [String] = [
        "Certificate",
        "Password"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Import Certificate"
        
        let importButton: UIBarButtonItem = UIBarButtonItem(
            title: "Submit",
            style: .done,
            target: self,
            action: #selector(importButton)
        )
        self.navigationItem.setRightBarButton(importButton, animated: true)
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.isScrollEnabled = false
        self.tableView.rowHeight = 44
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                if let sheet = self.navigationController?.sheetPresentationController {
                    DispatchQueue.main.async {
                        sheet.animateChanges {
                            sheet.detents = [
                                .custom { context in
                                    let contentHeight = self.tableView.contentSize.height + 50
                                    return contentHeight
                                }
                            ]
                        }
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cert = ImportTableCell(parent: self)
            cell = cert!
            break
        case 1:
            cell = UITableViewCell()
            self.textField = UITextField(frame: CGRect(x: 15, y: 0, width: tableView.frame.width - 30, height: 44))
            self.textField?.placeholder = "ie. 123456"
            self.textField?.delegate = self
            cell.contentView.addSubview(textField!)
        default:
            cell = UITableViewCell()
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func importButton() {
        do {
            let p12Data: Data = try Data(contentsOf: URL(fileURLWithPath: self.cert!.url!.path))
            let appGroupUserDefault = UserDefaults.init(suiteName: LCUtils.appGroupID()) ?? UserDefaults.standard
            appGroupUserDefault.set(p12Data, forKey: "LCCertificateData")
            appGroupUserDefault.set(textField?.text ?? "", forKey: "LCCertificatePassword")
            appGroupUserDefault.set(NSDate.now, forKey: "LCCertificateUpdateDate")
            UserDefaults.standard.set(LCUtils.appGroupID(), forKey: "LCAppGroupID")
        } catch {
            NotificationServer.NotifyUser(level: .error, notification: "Something went wrong importing the CertBlob! \(error.localizedDescription)")
        }
        
        self.dismiss(animated: true)
    }
}
