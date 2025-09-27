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

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
}

// 监听语言变化通知
extension UIViewController {
    func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc func languageChanged() {
        // 子类可以重写此方法来处理语言变化
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    func removeLanguageObserver() {
        NotificationCenter.default.removeObserver(self, name: .languageChanged, object: nil)
    }
}

// 为UI组件添加本地化支持
extension UILabel {
    func setLocalizedText(_ key: String) {
        self.text = key.localized
    }
}

extension UIButton {
    func setLocalizedTitle(_ key: String, for state: UIControl.State = .normal) {
        self.setTitle(key.localized, for: state)
    }
}

extension UINavigationItem {
    func setLocalizedTitle(_ key: String) {
        self.title = key.localized
    }
}

extension UIAlertController {
    convenience init(localizedTitle titleKey: String, localizedMessage messageKey: String, preferredStyle style: UIAlertController.Style) {
        self.init(title: titleKey.localized, message: messageKey.localized, preferredStyle: style)
    }
    
    func addLocalizedAction(title key: String, style: UIAlertAction.Style = .default, handler: ((UIAlertAction) -> Void)? = nil) {
        self.addAction(UIAlertAction(title: key.localized, style: style, handler: handler))
    }
}
