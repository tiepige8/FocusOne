import SwiftUI

struct HistoryView: View {
    @ObservedObject var manager: TaskManager; var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("历史归档").font(.headline).foregroundColor(.primary)
                Spacer()
                Button(action: { manager.copyHistoryToMarkdown() }) { Image(systemName: "doc.on.clipboard").font(.title3).foregroundColor(manager.currentTheme.accentColor) }.buttonStyle(.plain).help("复制 Markdown")
                Button(action: onClose) { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary).padding(6).background(Color.primary.opacity(0.05)).clipShape(Circle()) }.buttonStyle(.plain).padding(.leading, 8)
            }.padding(20)
            
            HStack(spacing: 20) {
                StatCard(title: "已完成", value: "\(manager.historyTasks.count)")
                Divider().frame(height: 24)
                StatCard(title: "总时长", value: manager.formatDuration(manager.totalHistoryDuration))
            }.padding().frame(maxWidth: .infinity).background(manager.currentTheme.secondaryColor).cornerRadius(12).padding(.horizontal, 20)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.historyTasks) { task in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(task.title).strikethrough().foregroundColor(.secondary)
                                Spacer()
                                Text(manager.formatDuration(task.totalDuration())).font(.caption).monospacedDigit().padding(4).background(Color.primary.opacity(0.05)).cornerRadius(4)
                            }
                            HStack {
                                Text(manager.dateFormatter.string(from: task.sessions.last?.endTime ?? task.updateDate)).font(.caption2).foregroundColor(.secondary)
                                Spacer()
                                if !task.tags.isEmpty { HStack { ForEach(task.tags, id: \.self) { tag in Text("#"+tag).font(.caption2).foregroundColor(manager.currentTheme.accentColor) } } }
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                }.padding(.vertical, 10)
            }
        }
        .frame(width: 360, height: 520) // 统一尺寸
        .background(Color(nsColor: .windowBackgroundColor)).cornerRadius(16).shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}
