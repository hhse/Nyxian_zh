# Nyxian 本地化说明

## 概述
本项目已成功实现中文本地化，支持简体中文和英文两种语言。

## 本地化文件结构
```
Nyxian/
├── zh-Hans.lproj/
│   └── Localizable.strings    # 中文本地化文件
├── en.lproj/
│   └── Localizable.strings    # 英文本地化文件
└── UI/
    ├── Settings/
    │   └── LanguageSettings.swift    # 语言设置界面
    └── UIInit/
        └── LocalizationExtension.swift    # 本地化扩展
```

## 功能特性

### 1. 语言切换
- 在设置界面新增"语言"选项
- 支持简体中文和英文切换
- 切换语言后需要重启应用生效

### 2. 本地化内容
已翻译的界面包括：
- 主界面：项目列表、创建项目、导入等
- 设置界面：所有设置选项
- 文件操作：创建、复制、移动、重命名、删除等
- 菜单界面：所有子菜单和上下文菜单
- 对话框：警告、错误、确认等提示信息

### 3. 技术实现
- 使用 `.lproj` 目录结构进行本地化
- 创建了 `LanguageManager` 单例管理语言设置
- 扩展了 `String` 类型支持 `.localized` 属性
- 实现了语言变化通知机制

## 使用方法

### 切换语言
1. 打开应用
2. 进入"设置"界面
3. 选择"语言"选项
4. 选择"简体中文"或"English"
5. 确认重启应用

### 添加新语言
1. 创建新的 `.lproj` 目录（如 `ja.lproj` 用于日语）
2. 复制 `Localizable.strings` 文件
3. 翻译所有字符串值
4. 在 `LanguageSettings.swift` 中添加新语言选项

### 添加新的本地化字符串
1. 在 `Localizable.strings` 文件中添加新的键值对
2. 在代码中使用 `"Key".localized` 获取本地化字符串

## 文件说明

### Localizable.strings
包含所有需要本地化的字符串，格式为：
```
"Key" = "Value";
```

### LanguageManager.swift
语言管理器，负责：
- 获取和设置当前语言
- 提供本地化字符串获取方法
- 发送语言变化通知

### LocalizationExtension.swift
本地化扩展，提供：
- `String.localized` 属性
- UI组件本地化支持
- 语言变化监听机制

## 注意事项
1. 所有硬编码的字符串都应该使用本地化
2. 新增字符串时记得同时更新所有语言文件
3. 语言切换需要重启应用才能完全生效
4. 建议在开发时使用英文作为默认语言

## 贡献指南
如需添加新的本地化内容：
1. 在代码中使用 `"Key".localized` 替代硬编码字符串
2. 在 `Localizable.strings` 文件中添加对应的键值对
3. 确保所有语言文件都包含相同的键
