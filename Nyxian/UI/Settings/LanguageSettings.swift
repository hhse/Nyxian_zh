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

class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "AppLanguage"
    
    var currentLanguage: String {
        get {
            return UserDefaults.standard.string(forKey: languageKey) ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: languageKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func localizedString(for key: String) -> String {
        let language = currentLanguage
        let bundle = Bundle.main
        
        if let path = bundle.path(forResource: language, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle.localizedString(forKey: key, value: key, table: nil)
        }
        
        // 回退到默认语言
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// 语言设置界面
class LanguageSettingsViewController: UIThemedTableViewController {
    
    private let languages = [
        ("en", "English"),
        ("zh-Hans", "简体中文")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Language".localized
        self.tableView.rowHeight = 44
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let language = languages[indexPath.row]
        
        cell.textLabel?.text = language.1
        cell.accessoryType = LanguageManager.shared.currentLanguage == language.0 ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedLanguage = languages[indexPath.row]
        if LanguageManager.shared.currentLanguage != selectedLanguage.0 {
            LanguageManager.shared.setLanguage(selectedLanguage.0)
            
            // 显示重启提示
            let alert = UIAlertController(
                title: "Warning".localized,
                message: "Language change will take effect after restart. Do you want to restart now?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
            alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in
                // 重启应用
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                exit(0)
            })
            
            present(alert, animated: true)
        }
    }
}
