# FocusOne

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg?style=flat)
![Language](https://img.shields.io/badge/language-Swift-orange.svg?style=flat)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)

FocusOne 是一款纯 SwiftUI 构建的 macOS 极简任务管理器。它强制执行单任务工作流（Single-tasking），旨在维持心流并减少上下文切换成本。

不同于传统的 Todo 清单应用，FocusOne 仅在悬浮窗中展示当前正在进行的唯一任务，极大降低视觉干扰。

## 特性

- **单任务专注**：独立界面展示当前活跃任务，配备大字号计时器。
- **动态悬浮窗**：闲置时自动收缩为离散的迷你胶囊，置顶于所有窗口之上，支持拖拽。
- **反拖延机制**：限制“稍后处理”的任务数量（Max 6），防止待办事项无限堆积。
- **快速捕获**：顶层常驻输入框，不打断当前工作流即可瞬间记录想法。
- **本地存储**：数据以本地 JSON 格式存储。支持自定义存储路径，可配合 iCloud Drive 或 Dropbox 实现同步。
- **Markdown 导出**：一键导出每日任务与笔记详情，便于后续分析
- **深色模式**：原生适配 Light/Dark 主题。

## 安装

由于应用未进行 Apple Developer ID 签名，首次启动需绕过 Gatekeeper 验证：

1. 下载 `FocusOne.dmg` 或应用二进制文件。
2. 将应用拖入 `/Applications` 文件夹。
3. **右键点击** 应用图标并选择 **打开 (Open)**。
4. 在弹出的确认框中点击 **打开 (Open)**。

*此步骤仅在首次运行时需要。*

## 开发环境

### 要求

- macOS 12.0+
- Xcode 14.0+
- Swift 5.5+

### 架构

项目遵循严格的 **MVVM** 模式：

- **Models**: 核心数据定义 (`TaskItem`, `AppTheme`)。
- **ViewModels**: 业务逻辑与数据持久化 (`TaskManager`)。
- **Views**: 按功能拆分的 UI 组件 (`FullView`, `MiniFocusView`, `SettingsView`)。
- **Persistence**: 基于 `Codable` 的 JSON 存储，集成 `NSOpenPanel` 实现数据迁移。

## 路线图

- [ ] 全局快捷键唤醒支持
- [ ] 每日专注时长热力图
- [ ] 番茄钟倒计时模式

## 许可证

MIT License
