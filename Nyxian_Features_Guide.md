# Nyxian 功能指南

## 🌏 汉化功能

### 概述
Nyxian 已完全汉化，提供中文界面支持，让中文用户能够更轻松地使用应用。

### 汉化内容
- ✅ **主界面** - 所有按钮、标签、菜单项
- ✅ **设置页面** - 配置选项和说明文字
- ✅ **错误提示** - 用户友好的中文错误信息
- ✅ **状态信息** - 构建、安装、打包状态提示
- ✅ **调试信息** - 控制台输出的中文调试信息

### 汉化文件位置
```
Nyxian/zh-Hans.lproj/Localizable.strings
```

### 主要汉化内容示例
```swift
// 主界面
"Build" = "构建";
"Install" = "安装";
"Package" = "打包";
"Settings" = "设置";

// 状态信息
"Building..." = "构建中...";
"Installing..." = "安装中...";
"Packaging..." = "打包中...";
"Success" = "成功";
"Failed" = "失败";

// 错误提示
"No code signature present" = "未找到代码签名";
"Failed to install application" = "应用安装失败";
"Failed to create IPA package" = "IPA 打包失败";
```

---

## 🔐 证书检测跳过功能

### 概述
证书检测跳过功能专为越狱设备和 TrollStore 用户设计，允许在没有有效开发者证书的情况下构建和安装应用。

### 功能特点
- 🚫 **跳过签名验证** - 无需开发者证书
- 📱 **越狱设备支持** - 适用于已越狱的 iOS 设备
- 🛠️ **TrollStore 兼容** - 支持 TrollStore 安装方式
- 📦 **自动打包** - 生成 IPA 文件供手动安装

### 启用方法
1. 打开 Nyxian 应用
2. 进入 **设置** → **杂项**
3. 开启 **"跳过证书检查"** 选项

### 工作流程

#### 启用跳过证书检查时：
```
1. 选择要构建的应用
2. 点击"构建"按钮
3. 系统自动跳过签名验证
4. 直接创建 IPA 文件
5. 显示 IPA 文件路径
6. 可选择用 Filza 打开文件位置
```

#### 未启用跳过证书检查时：
```
1. 选择要构建的应用
2. 点击"构建"按钮
3. 检查开发者证书
4. 对应用进行签名
5. 直接安装到设备
6. 启动应用
```

### 技术实现

#### 核心代码逻辑
```swift
// 检查是否跳过证书检查
let skipCertificateCheck = UserDefaults.standard.bool(forKey: "SkipCertificateCheck")

if skipCertificateCheck {
    // 跳过签名，直接打包
    try self.package()
    // 显示 IPA 路径
    self.showIPAPathAndOpenWithFilza(ipaPath: ipaPath)
} else {
    // 正常签名流程
    LCAppInfo(bundlePath: project.bundlePath)?.patchExecAndSignIfNeed(...)
}
```

#### 打包过程增强
```swift
func package() throws {
    // 1. 验证 payload 目录存在
    // 2. 创建必要的父目录
    // 3. 执行 ZIP 压缩
    // 4. 验证 IPA 文件创建成功
    // 5. 显示详细调试信息
}
```

### 调试信息
启用跳过证书检查后，控制台会显示详细的调试信息：

```
[DEBUG] Starting package process...
[DEBUG] Payload path: /path/to/Payload
[DEBUG] Package path: /path/to/app.ipa
[DEBUG] Created package directory: /path/to/
Starting ZIP creation from: /path/to/Payload to: /path/to/app.ipa
ZIP creation completed. Processed X files.
[DEBUG] Package completed in X seconds, result: true
[DEBUG] IPA file created successfully: /path/to/app.ipa (Size: X bytes)
```

### 使用场景

#### 适用情况：
- ✅ 越狱设备用户
- ✅ TrollStore 用户
- ✅ 没有开发者证书的用户
- ✅ 需要手动安装 IPA 的场景

#### 不适用情况：
- ❌ 需要 App Store 分发
- ❌ 企业证书分发
- ❌ 需要完整签名验证的场景

### 注意事项

1. **安全性**：跳过证书检查会绕过 iOS 的安全验证，请确保只安装可信的应用
2. **兼容性**：此功能主要针对越狱设备和 TrollStore，普通设备可能无法使用
3. **法律性**：请遵守当地法律法规，不要用于非法用途
4. **备份**：建议在修改系统应用前进行完整备份

### 故障排除

#### 常见问题：
1. **IPA 文件未生成**
   - 检查 payload 目录是否存在
   - 查看控制台调试信息
   - 确认有足够的存储空间

2. **Filza 无法打开**
   - 确认已安装 Filza 应用
   - 检查文件路径是否正确
   - 尝试手动导航到文件位置

3. **应用无法安装**
   - 确认设备已越狱或支持 TrollStore
   - 检查 IPA 文件是否完整
   - 尝试使用其他安装工具

### 更新日志

#### v1.0.0
- ✅ 完整汉化支持
- ✅ 证书检测跳过功能
- ✅ 自动 IPA 打包
- ✅ Filza 集成
- ✅ 详细调试日志
- ✅ 错误处理和用户提示

---

## 📞 技术支持

如果您在使用过程中遇到问题，请：

1. 查看控制台调试信息
2. 检查设备兼容性
3. 确认相关设置正确
4. 参考故障排除部分

**祝您使用愉快！** 🎉
