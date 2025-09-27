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

@objc class ContentViewController: UITableViewController, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
    var sessionIndex: IndexPath? = nil
    var projects: [NXProject] = []
    var path: String
    
    @objc init(path: String) {
        RevertUI()
        
        LDEApplicationWorkspace.shared()
        Bootstrap.shared.bootstrap()
        
        self.path = path
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Projects".localized
        
        let createItem: UIAction = UIAction(title: "Create Project".localized, image: UIImage(systemName: "plus")) { [weak self] _ in
            guard let self = self else { return }
            self.createProject(mode: .app)
        }
        
        let importItem: UIAction = UIAction(title: "Import".localized, image: UIImage(systemName: "square.and.arrow.down.fill")) { [weak self] _ in
            guard let self = self else { return }
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip], asCopy: true)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = .formSheet
            self.present(documentPicker, animated: true)
        }
        let menu: UIMenu = UIMenu(children: [createItem, importItem])
        
        let barbutton: UIBarButtonItem = UIBarButtonItem()
        barbutton.menu = menu
        barbutton.image = UIImage(systemName: "plus")
        self.navigationItem.setRightBarButton(barbutton, animated: false)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.rowHeight = 70
        
        self.projects = NXProject.listProjects(atPath: self.path) as! [NXProject]
        
        self.tableView.reloadData()
    }
    
    func createProject(mode: NXProjectType) {
        let alert = UIAlertController(localizedTitle: "Create Project",
                                      localizedMessage: "",
                                      preferredStyle: .alert)
        
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Name".localized
        }
        
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Bundle Identifier".localized
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
        
        let createAction: UIAlertAction = UIAlertAction(title: "Create".localized, style: .default) { [weak self] action -> Void in
            guard let self = self else { return }
            let name = (alert.textFields![0]).text!
            let bundleid = (alert.textFields![1]).text!
            
            self.projects.append(NXProject.createProject(
                atPath: self.path,
                withName: name,
                withBundleIdentifier: bundleid,
                withType: mode
            ))
            
            let newIndexPath = IndexPath(row: self.projects.count - 1, section: 0)
            
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(createAction)
        
        self.present(alert, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let indexPath = sessionIndex {
            let selectedProject: NXProject = self.projects[indexPath.row]
            selectedProject.reload()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            sessionIndex = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedProject: NXProject = self.projects[indexPath.row]
        return NXProjectTableCell(project: selectedProject)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        sessionIndex = indexPath
        
        let selectedProject: NXProject = self.projects[indexPath.row]
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let padFileVC: MainSplitViewController = MainSplitViewController(project: selectedProject)
            padFileVC.modalPresentationStyle = .fullScreen
            self.present(padFileVC, animated: true)
        } else {
            let fileVC = FileListViewController(project: selectedProject)
            self.navigationController?.pushViewController(fileVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let export: UIAction = UIAction(title: "Export".localized, image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] _ in
                DispatchQueue.global().async {
                    guard let self = self else { return }
                    let project = self.projects[indexPath.row]
                    zipDirectoryAtPath(project.path, "\(NSTemporaryDirectory())/\(project.projectConfig.displayName!).zip", true)
                    share(url: URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(project.projectConfig.displayName!).zip"), remove: true)
                }
            }
            
            let item: UIAction = UIAction(title: "Remove".localized, image: UIImage(systemName: "trash.fill"), attributes: .destructive) { _ in
                let project = self.projects[indexPath.row]
                
                self.presentConfirmationAlert(
                    title: "Warning",
                    message: "Are you sure you want to remove \"\(project.projectConfig.displayName!)\"?",
                    confirmTitle: "Remove",
                    confirmStyle: .destructive)
                { [weak self] in
                    guard let self = self else { return }
                    NXProject.remove(project)
                    self.projects.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
            
            let settings: UIAction = UIAction(title: "Settings".localized, image: UIImage(systemName: "gear")) { _ in
                let settingsViewController: UINavigationController = UINavigationController(rootViewController: ProjectSettingsViewController(style: .insetGrouped, project: self.projects[indexPath.row]))
                settingsViewController.modalPresentationStyle = .formSheet
                settingsViewController.presentationController?.delegate = self
                self.present(settingsViewController, animated: true)
            }
            
            return UIMenu(children: [export, item, settings])
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        do {
            guard let selectedURL = urls.first else { return }
            
            let extractFirst: URL = URL(fileURLWithPath: "\(NSTemporaryDirectory())Proj")
            try FileManager.default.createDirectory(at: extractFirst, withIntermediateDirectories: true)
            unzipArchiveAtPath(selectedURL.path, extractFirst.path)
            let items: [String] = try FileManager.default.contentsOfDirectory(atPath: "\(NSTemporaryDirectory())Proj")
            let projectPath: String = "\(Bootstrap.shared.bootstrapPath("/Projects"))/\(UUID().uuidString)"
            try FileManager.default.moveItem(atPath: extractFirst.appendingPathComponent(items.first ?? "").path, toPath: projectPath)
            try FileManager.default.removeItem(at: extractFirst)
            
            self.projects.append(NXProject(path: projectPath))
            let newIndexPath = IndexPath(row: self.projects.count - 1, section: 0)
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        } catch {
            NotificationServer.NotifyUser(level: .error, notification: error.localizedDescription)
        }
    }
}
