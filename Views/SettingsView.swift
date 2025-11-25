import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: TaskManager; @Binding var opacityMain: Double; @Binding var opacityMiniContent: Double; var onClose: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text("偏好设置").font(.headline).foregroundColor(.primary); Spacer(); Button(action: onClose) { Image(systemName: "xmark").foregroundColor(.secondary).padding(6).background(Color.primary.opacity(0.05)).clipShape(Circle()) }.buttonStyle(.plain) }.padding(20)
            ScrollView { VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) { Text("主题风格").font(.caption).foregroundColor(.secondary); HStack(spacing: 12) { ForEach(AppTheme.presets) { theme in Circle().fill(theme.accentColor).frame(width: 24, height: 24).overlay(Circle().stroke(Color.primary, lineWidth: manager.selectedThemeIndex == theme.id ? 2 : 0).padding(-3)).onTapGesture { withAnimation { manager.selectedThemeIndex = theme.id } } } } }
                VStack(alignment: .leading, spacing: 10) { Text("外观与透明度").font(.caption).foregroundColor(.secondary); OpacitySliderRow(label: "主窗口", value: $opacityMain); OpacitySliderRow(label: "悬浮窗", value: $opacityMiniContent) }
                VStack(alignment: .leading, spacing: 10) { Text("数据存储").font(.caption).foregroundColor(.secondary); HStack { Image(systemName: "folder").foregroundColor(manager.currentTheme.accentColor); Text(manager.currentDisplayPath).font(.caption).lineLimit(1).truncationMode(.middle).foregroundColor(.primary); Spacer(); Button("迁移...") { selectFolder() }.font(.caption).padding(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3))).buttonStyle(.plain) }.padding(10).background(Color.primary.opacity(0.05)).cornerRadius(8)
                    // 【修改】提示文案 FocusOne
                    Text("注意：更改位置会将您现有的 FocusOne 数据移动到新文件夹。").font(.caption2).foregroundColor(.secondary) }
                // 【修改】版本信息 FocusOne
                VStack(alignment: .leading, spacing: 12) { Text("通用").font(.subheadline).bold().foregroundColor(.secondary); Divider(); Text("FocusOne v1.0").font(.caption).foregroundColor(.secondary) }
            }.padding(.horizontal, 20).padding(.bottom, 20) }
        }.frame(width: 320, height: 400).background(Color(nsColor: .windowBackgroundColor)).cornerRadius(16).shadow(radius: 20)
    }
    // 【修改】弹窗提示 FocusOne
    func selectFolder() { let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false; panel.prompt = "选择位置"; panel.message = "请选择 FocusOne 数据的存储文件夹"; if panel.runModal() == .OK, let url = panel.url { manager.updateDataLocation(to: url) } }
}
