import SwiftUI

struct OpacitySliderRow: View {
    let label: String; @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(label).font(.system(size: 13)); Spacer(); Text("\(Int(value * 100))%").font(.caption).monospacedDigit().foregroundColor(.secondary) }
            Slider(value: $value, in: 0.1...1.0).controlSize(.small)
        }
    }
}

struct InboxTaskRow: View {
    let task: TaskItem; let dateFormatter: DateFormatter; let formattedDuration: String?; var themeColor: Color = .blue
    let onDoubleClick: () -> Void; let onQuickArchive: () -> Void; let onStartFocus: () -> Void
    
    var body: some View {
        HStack(spacing: 14) { // 间距加大
            Circle().fill(task.isPaused ? Color.orange : themeColor).frame(width: 8, height: 8) // 圆点稍微大一点点
            
            VStack(alignment: .leading, spacing: 4) { // 垂直间距加大
                // 标题加大加粗
                Text(task.title)
                    .font(.system(size: 17, weight: .medium)) // 15 -> 17
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                // 日期加大，更清晰
                Text(dateFormatter.string(from: task.creationDate))
                    .font(.system(size: 12)) // 10 -> 12
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle()).onTapGesture(count: 2, perform: onDoubleClick)
            
            Spacer()
            
            if let durationStr = formattedDuration {
                Text(durationStr)
                    .font(.system(size: 13, design: .monospaced)) // 12 -> 13
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) { // 按钮间距加大
                Button(action: onQuickArchive) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14)) // 图标加大
                        .foregroundColor(.secondary)
                        .padding(6)
                }.buttonStyle(.plain)
                
                Button(action: onStartFocus) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(8) // 点击区域加大
                        .background(Circle().fill(themeColor))
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10) // 行高加大
        .overlay(Divider().opacity(0.5), alignment: .bottom)
    }
}

struct CustomAlertView: View {
    let title: String; let message: String; let buttonText: String; let action: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 44)).foregroundColor(.orange).padding(.top, 28).padding(.bottom, 16)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                Text(message).font(.system(size: 15)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 20).lineSpacing(4)
            }.padding(.bottom, 32)
            Button(action: action) { Text(buttonText).font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 14) }.buttonStyle(.borderedProminent).tint(.primary).controlSize(.large).padding(.horizontal, 24).padding(.bottom, 24)
        }.frame(width: 320).background(Color(nsColor: .windowBackgroundColor)).cornerRadius(24).shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
    }
}

struct ActionButton: View { let icon: String; let label: String; let color: Color; let action: () -> Void; var body: some View { Button(action: action) { HStack(spacing: 6) { Image(systemName: icon); Text(label) }.font(.system(size: 15, weight: .bold)).foregroundColor(color).padding(.horizontal, 18).padding(.vertical, 10).background(color.opacity(0.1)).cornerRadius(20) }.buttonStyle(.plain) } }

struct StatCard: View { let title: String; let value: String; var body: some View { VStack(spacing: 4) { Text(value).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.primary); Text(title).font(.caption).foregroundColor(.secondary) } } }
