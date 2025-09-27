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

func FindFilesStack(
    _ projectPath: String,
    _ fileExtensions: [String],
    _ ignore: [String]
) -> [String] {
    do {
        let (fileExtensionsSet, ignoreSet, allPaths) = (
            Set(fileExtensions),
            Set(ignore),
            try FileManager.default.subpathsOfDirectory(atPath: projectPath)
        )

        var matchedFiles: [String] = []

        for relativePath in allPaths {
            let fullPath = "\(projectPath)/\(relativePath)"

            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue {
                if fileExtensionsSet.contains(where: { relativePath.hasSuffix($0) }) &&
                   !ignoreSet.contains(where: { relativePath.hasPrefix($0) }) {
                    matchedFiles.append(fullPath)
                }
            }
        }
        return matchedFiles
    } catch {
        return []
    }
}
