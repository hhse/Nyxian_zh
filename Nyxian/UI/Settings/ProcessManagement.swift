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

class ProcessManagementViewController: UIThemedTableViewController {
    enum Section {
        case main
    }

    var processes: [LDEProcess] = []
    private var refreshTimer: Timer?
    private var dataSource: UITableViewDiffableDataSource<Section, Int32>!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Process Management"
        tableView.register(ProcessCell.self, forCellReuseIdentifier: ProcessCell.reuseID)

        dataSource = UITableViewDiffableDataSource<Section, Int32>(tableView: tableView) { [weak self] tableView, indexPath, pid in
            let cell = tableView.dequeueReusableCell(withIdentifier: ProcessCell.reuseID, for: indexPath) as! ProcessCell
            if let process = self?.processes.first(where: { $0.pid == pid }) {
                cell.configure(with: process)
            }
            return cell
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRefreshing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRefreshing()
    }
    
    deinit {
        stopRefreshing()
    }

    private func startRefreshing() {
        stopRefreshing()
        refreshProcesses()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshProcesses()
        }
        RunLoop.current.add(refreshTimer!, forMode: .common)
    }
    
    private func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshProcesses() {
        var updatedProcesses: [LDEProcess] = []
        for value in LDEProcessManager.shared().processes {
            let number = value.0 as! NSNumber
            if let proc = LDEProcessManager.shared().process(forProcessIdentifier: number.int32Value) {
                updatedProcesses.append(proc)
            }
        }
        processes = updatedProcesses

        var snapshot = NSDiffableDataSourceSnapshot<Section, Int32>()
        snapshot.appendSections([.main])
        snapshot.appendItems(processes.map { $0.pid })
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let pid = dataSource.itemIdentifier(for: indexPath),
              let process = processes.first(where: { $0.pid == pid }) else {
            return nil
        }
        
        let killAction = UIContextualAction(style: .destructive, title: "Kill") { _, _, completion in
            if process.terminate() {
                self.processes.removeAll { $0.pid == pid }
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteItems([pid])
                self.dataSource.apply(snapshot, animatingDifferences: true)
            } else {
                NotificationServer.NotifyUser(level: .error, notification: "Could not kill \(process.pid)")
            }
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [killAction])
    }
}
