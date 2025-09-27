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

class SettingsViewController: UIThemedTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings".localized
        setupFooter()
    }
    
    private func setupFooter() {
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)
        
        // 创建主标签
        let mainLabel = UILabel()
        mainLabel.text = "汉化等增强功能 by @mumu"
        mainLabel.font = UIFont.systemFont(ofSize: 12)
        mainLabel.textColor = UIColor.systemGray
        mainLabel.textAlignment = .center
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建可点击的GitHub链接
        let githubButton = UIButton(type: .system)
        githubButton.setTitle("GitHub: https://github.com/hhse/Nyxian_zh00", for: .normal)
        githubButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        githubButton.setTitleColor(UIColor.systemBlue, for: .normal)
        githubButton.titleLabel?.textAlignment = .center
        githubButton.titleLabel?.numberOfLines = 1
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        githubButton.addTarget(self, action: #selector(openGitHubLink), for: .touchUpInside)
        
        footerView.addSubview(mainLabel)
        footerView.addSubview(githubButton)
        
        NSLayoutConstraint.activate([
            mainLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            mainLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20),
            mainLabel.leadingAnchor.constraint(greaterThanOrEqualTo: footerView.leadingAnchor, constant: 20),
            mainLabel.trailingAnchor.constraint(lessThanOrEqualTo: footerView.trailingAnchor, constant: -20),
            
            githubButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            githubButton.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 4),
            githubButton.leadingAnchor.constraint(greaterThanOrEqualTo: footerView.leadingAnchor, constant: 20),
            githubButton.trailingAnchor.constraint(lessThanOrEqualTo: footerView.trailingAnchor, constant: -20)
        ])
        
        tableView.tableFooterView = footerView
    }
    
    @objc private func openGitHubLink() {
        if let url = URL(string: "https://github.com/hhse/Nyxian_zh00") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator

        switch indexPath.row {
        case 0:
            cell.imageView?.image = UIImage(systemName: {
                if #available(iOS 16.0, *) {
                    return "wrench.adjustable.fill"
                } else {
                    return "gearshape.2.fill"
                }
            }())
            cell.textLabel?.text = "Toolchain".localized
            break
        case 1:
            cell.imageView?.image = UIImage(systemName: "app.badge.fill")
            cell.textLabel?.text = "Application Management".localized
            break
        case 2:
            cell.imageView?.image = UIImage(systemName: "apple.terminal.fill")
            cell.textLabel?.text = "Process Management".localized
            break
        case 3:
            cell.imageView?.image = UIImage(systemName: "paintbrush.fill")
            cell.textLabel?.text = "Customization".localized
            break
        case 4:
            cell.imageView?.image = UIImage(systemName: "tray.2.fill")
            cell.textLabel?.text = "Miscellaneous".localized
            break
        case 5:
            cell.imageView?.image = UIImage(systemName: "person.3.sequence.fill")
            cell.textLabel?.text = "Credits".localized
            break
        case 6:
            cell.imageView?.image = UIImage(systemName: "globe")
            cell.textLabel?.text = "Language".localized
            break
        case 7:
            cell.imageView?.image = UIImage(systemName: "info")
            cell.textLabel?.text = "Info".localized
            break
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigateToController(for: indexPath.row, animated: true)
    }

    private func navigateToController(for index: Int, animated: Bool) {
        guard let viewController: UIViewController = {
            switch index {
            case 0:
                return ToolChainController(style: .insetGrouped)
            case 1:
                return ApplicationManagementViewController(style: .insetGrouped)
            case 2:
                return ProcessManagementViewController(style: .insetGrouped)
            case 3:
                return CustomizationViewController(style: .insetGrouped)
            case 4:
                return MiscellaneousController(style: .insetGrouped)
            case 5:
                return CreditsViewController(style: .insetGrouped)
            case 6:
                return LanguageSettingsViewController(style: .insetGrouped)
            case 7:
                return AppInfoViewController(style: .insetGrouped)
            default:
                return nil
            }
        }() else { return }

        navigationController?.pushViewController(viewController, animated: animated)
    }
}
