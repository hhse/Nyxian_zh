# Nyxian 打包进度卡住问题诊断与解决方案

## 问题分析

根据代码分析，打包进度卡住可能发生在以下几个阶段：

### 1. **Bootstrap 初始化阶段**
```swift
// Bootstrap.swift:190-192
while Bootstrap.shared.bootstrapVersion != Bootstrap.shared.newestBootstrapVersion {
    Thread.sleep(forTimeInterval: 1.0)
}
```
**可能问题**: Bootstrap 初始化失败或版本不匹配导致无限循环

### 2. **ZIP 打包阶段**
```objc
// zip.m:197-227
enumerator = [fileManager enumeratorAtPath:directoryPath];
while ((filePath = [enumerator nextObject])) {
    // 处理每个文件...
}
```
**可能问题**: 
- 文件系统权限问题
- 大文件处理超时
- 内存不足
- 文件路径包含特殊字符

### 3. **文件系统问题**
- 目标目录不存在或权限不足
- 磁盘空间不足
- 文件被其他进程占用

## 解决方案

### 方案1: 检查 Bootstrap 状态
```swift
// 在构建前检查 Bootstrap 状态
if Bootstrap.shared.bootstrapVersion != Bootstrap.shared.newestBootstrapVersion {
    print("Bootstrap not ready, current: \(Bootstrap.shared.bootstrapVersion), required: \(Bootstrap.shared.newestBootstrapVersion)")
    // 重新启动 Bootstrap
    Bootstrap.shared.bootstrap()
}
```

### 方案2: 改进 ZIP 打包函数
```objc
BOOL zipDirectoryAtPath(NSString *directoryPath, NSString *zipPath, BOOL keepParent) {
    // 添加超时机制
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeout = 300.0; // 5分钟超时
    
    // 检查目录是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directoryPath]) {
        NSLog(@"Directory does not exist: %@", directoryPath);
        return NO;
    }
    
    // 检查磁盘空间
    NSDictionary *attributes = [fileManager attributesOfFileSystemForPath:directoryPath error:nil];
    NSNumber *freeSpace = attributes[NSFileSystemFreeSize];
    if ([freeSpace longLongValue] < 100 * 1024 * 1024) { // 100MB
        NSLog(@"Insufficient disk space");
        return NO;
    }
    
    // 原有的 ZIP 逻辑...
    // 在循环中添加超时检查
    while ((filePath = [enumerator nextObject])) {
        if ([NSDate timeIntervalSinceReferenceDate] - startTime > timeout) {
            NSLog(@"ZIP operation timed out");
            return NO;
        }
        // 处理文件...
    }
}
```

### 方案3: 添加进度回调
```swift
func package() throws {
    // 添加进度回调
    DispatchQueue.main.async {
        XCodeButton.updateProgress(progress: 0.8)
    }
    
    let result = zipDirectoryAtPath(project.payloadPath, project.packagePath, true)
    
    if !result {
        throw NSError(domain: "com.cr4zy.nyxian.builder.package", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP package"])
    }
    
    DispatchQueue.main.async {
        XCodeButton.updateProgress(progress: 1.0)
    }
}
```

### 方案4: 检查项目配置
```swift
// 在打包前检查项目配置
func validateProjectForPackaging() throws {
    // 检查 Bundle ID
    guard !project.projectConfig.bundleid!.isEmpty else {
        throw NSError(domain: "com.cr4zy.nyxian.builder.validate", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "Bundle ID is empty"])
    }
    
    // 检查可执行文件名
    guard !project.projectConfig.executable!.isEmpty else {
        throw NSError(domain: "com.cr4zy.nyxian.builder.validate", code: 2, 
                     userInfo: [NSLocalizedDescriptionKey: "Executable name is empty"])
    }
    
    // 检查目录权限
    let fileManager = FileManager.default
    guard fileManager.isWritableFile(atPath: project.payloadPath) else {
        throw NSError(domain: "com.cr4zy.nyxian.builder.validate", code: 3, 
                     userInfo: [NSLocalizedDescriptionKey: "No write permission to payload directory"])
    }
}
```

## 调试步骤

### 1. 检查日志
```swift
// 在 Builder.swift 中添加详细日志
func package() throws {
    print("[DEBUG] Starting package process...")
    print("[DEBUG] Payload path: \(project.payloadPath)")
    print("[DEBUG] Package path: \(project.packagePath)")
    
    let startTime = Date()
    let result = zipDirectoryAtPath(project.payloadPath, project.packagePath, true)
    let duration = Date().timeIntervalSince(startTime)
    
    print("[DEBUG] Package completed in \(duration) seconds, result: \(result)")
    
    if !result {
        throw NSError(domain: "com.cr4zy.nyxian.builder.package", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "ZIP creation failed"])
    }
}
```

### 2. 检查文件系统
```swift
// 检查目录结构和权限
func debugFileSystem() {
    let fileManager = FileManager.default
    
    print("[DEBUG] Checking payload directory...")
    print("[DEBUG] Exists: \(fileManager.fileExists(atPath: project.payloadPath))")
    print("[DEBUG] Is directory: \(fileManager.fileExists(atPath: project.payloadPath) && fileManager.isDirectory(atPath: project.payloadPath))")
    print("[DEBUG] Is writable: \(fileManager.isWritableFile(atPath: project.payloadPath))")
    
    // 列出目录内容
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: project.payloadPath)
        print("[DEBUG] Directory contents: \(contents)")
    } catch {
        print("[DEBUG] Error listing directory: \(error)")
    }
}
```

### 3. 内存和性能监控
```swift
// 监控内存使用
func monitorMemoryUsage() {
    let memoryInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        print("[DEBUG] Memory usage: \(memoryInfo.resident_size / 1024 / 1024) MB")
    }
}
```

## 常见问题及解决方法

### 问题1: Bootstrap 卡住
**解决方法**: 重启应用或清除缓存
```swift
// 清除 Bootstrap 缓存
Bootstrap.shared.clearPath(path: "/")
Bootstrap.shared.bootstrap()
```

### 问题2: 文件权限问题
**解决方法**: 检查文件权限并修复
```swift
// 修复文件权限
try FileManager.default.setAttributes([.posixPermissions: 0o755], 
                                     ofItemAtPath: project.payloadPath)
```

### 问题3: 磁盘空间不足
**解决方法**: 清理缓存和临时文件
```swift
// 清理缓存
try? FileManager.default.removeItem(atPath: project.cachePath!)
try? FileManager.default.removeItem(atPath: NSTemporaryDirectory())
```

### 问题4: 大文件处理超时
**解决方法**: 分批处理或增加超时时间
```objc
// 在 zip.m 中添加文件大小检查
NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:nil];
NSNumber *fileSize = attributes[NSFileSize];
if ([fileSize longLongValue] > 100 * 1024 * 1024) { // 100MB
    NSLog(@"Large file detected: %@ (%@ bytes)", fullPath, fileSize);
    // 特殊处理大文件
}
```

## 建议的修复步骤

1. **立即检查**: 查看控制台日志，确定卡在哪个阶段
2. **清理缓存**: 删除项目缓存目录
3. **检查权限**: 确保应用有足够的文件系统权限
4. **重启应用**: 重新启动 Nyxian 应用
5. **检查磁盘空间**: 确保有足够的存储空间
6. **简化项目**: 尝试打包一个简单的测试项目

如果问题持续存在，建议：
- 检查 iOS 系统版本兼容性
- 更新到最新版本的 Nyxian
- 联系开发者获取技术支持
