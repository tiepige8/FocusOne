import SwiftUI

struct MiniFocusView: View {
    @ObservedObject var manager: TaskManager
    @Binding var editingTask: TaskItem?; @Binding var isCompletingFlow: Bool; var barOpacity: Double; var contentOpacity: Double
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.black.opacity(contentOpacity)).ignoresSafeArea()
            VStack(spacing: 0) {
                DragCapsuleView().padding(.top, 5)
                Spacer()
                VStack(spacing: 8) {
                    if let task = manager.focusTask {
                        Text(manager.formatDuration(task.currentSessionDuration())).font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundColor(.white).id(manager.currentTime).shadow(radius: 2)
                        Text(task.title).font(.system(size: 14)).foregroundColor(.white.opacity(0.9)).lineLimit(2).multilineTextAlignment(.center).padding(.horizontal, 16).frame(maxHeight: 40)
                    } else {
                        Text(manager.getBeijingTimeString()).font(.system(size: 30, weight: .bold, design: .monospaced)).foregroundColor(.white).id(manager.currentTime).shadow(radius: 2)
                        // 【修改】名称改为 FocusOne
                        Text("FocusOne").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer().frame(height: 12)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
struct DragCapsuleView: View { var body: some View { Capsule().fill(Color.gray.opacity(0.5)).frame(width: 100, height: 6) } }
