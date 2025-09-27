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

func getFileContentForName(filename: String) -> String {
    var content: String = ""
    var authgen: Bool = false
    var headergate: Bool = false
    
    // validate if we have to do stuff
    switch URL(fileURLWithPath: filename).pathExtension {
    case "c", "cpp", "m", "mm":
        authgen = true
        break
    case "h":
        authgen = true
        headergate = true
        break
    default:
        break
    }
    
    // now generate author if needed
    if authgen { content.append(NXUser.shared().generateHeader(forFileName: filename)) }
    if headergate {
        // generate header lock name macro
        let macroname: String = filename.uppercased().replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: " ", with: "_")
        
        // now append
        content.append("#ifndef \(macroname)\n#define \(macroname)\n\n#endif /* \(macroname) */")
    }
    
    return content
}
