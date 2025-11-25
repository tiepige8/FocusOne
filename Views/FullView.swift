import SwiftUI

struct FullView: View {
    @ObservedObject var manager: TaskManager
    @Binding var newTaskTitle: String; @Binding var showHistory: Bool; @Binding var showSettings: Bool
    @Binding var opacityMain: Double; @Binding var opacityMiniBar: Double; @Binding var opacityMiniContent: Double
    var onEnterMiniMode: () -> Void; @Binding var editingTask: TaskItem?; @Binding var isCompletingFlow: Bool; @Binding var showFocusConflictAlert: Bool
    
    var theme: AppTheme { manager.currentTheme }
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Part A: 顶部 Header 区域 ---
            ZStack(alignment: .top) {
                Color(nsColor: .windowBackgroundColor).opacity(opacityMain).ignoresSafeArea()
                theme.secondaryColor.opacity(0.3).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 工具栏
                    HStack {
                        Spacer()
                        Button(action: { withAnimation { showSettings = true } }) { Image(systemName: "gearshape.fill").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary) }.buttonStyle(.plain).help("应用设置").padding(.trailing, 10)
                        Button(action: onEnterMiniMode) { Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle").font(.system(size: 16)).foregroundColor(.secondary) }.buttonStyle(.plain).help("收起")
                    }.padding(.horizontal, 16).padding(.top, 12)
                    
                    if let focusTask = manager.focusTask {
                        // 专注状态
                        VStack(spacing: 6) {
                            Text("正在专注").font(.system(size: 12, weight: .bold)).foregroundColor(theme.accentColor).padding(.top, 4)
                            
                            // 【修改】标题字号微调 24 -> 22
                            Text(focusTask.title)
                                .font(.system(size: 22, weight: .bold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .foregroundColor(.primary)
                            
                            // 【核心修改】计时器字号 68 -> 52，权重 heavy -> bold
                            Text(manager.formatDuration(focusTask.currentSessionDuration()))
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(.vertical, -2) // 间距微调
                                .id(manager.currentTime)
                            
                            Text("累计: \(manager.formatDuration(focusTask.totalDuration()))").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.secondary)
                            
                            HStack(spacing: 30) {
                                ActionButton(icon: "pause.fill", label: "稍后", color: .orange) { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { manager.doLater(task: focusTask) } }
                                ActionButton(icon: "checkmark", label: "完成", color: theme.accentColor) { withAnimation { isCompletingFlow = true; editingTask = focusTask } }
                            }.padding(.top, 8)
                        }.padding(.bottom, 20)
                    } else {
                        // 空闲状态
                        VStack(spacing: 12) { Spacer(); Text("一次只做一件事").font(.system(size: 18, weight: .medium)).foregroundColor(.secondary); Spacer() }
                    }
                }
            }
            .frame(height: 220).zIndex(2)
            
            Divider()
            
            // --- Part B: 固定输入区域 ---
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("任务和灵感").font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                    Spacer()
                    Button(action: { withAnimation { showHistory = true } }) { Image(systemName: "clock.arrow.circlepath").font(.title3).foregroundColor(.secondary) }.buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
                
                HStack {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundColor(.secondary)
                    TextField("输入灵感，回车记录...", text: $newTaskTitle)
                        .font(.system(size: 16))
                        .textFieldStyle(.plain)
                        .onSubmit { if !newTaskTitle.isEmpty { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { manager.addTask(title: newTaskTitle) }; newTaskTitle = "" } }
                }
                .padding(12).background(Color.primary.opacity(0.05)).cornerRadius(12)
                .padding(.horizontal, 20).padding(.bottom, 15)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(opacityMain))
            .zIndex(1)
            
            // --- Part C: 滚动列表区域 ---
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(manager.inboxTasks) { task in
                        InboxTaskRow(
                            task: task,
                            dateFormatter: manager.shortDateFormatter,
                            formattedDuration: task.totalDuration() > 0 ? manager.formatDuration(task.totalDuration()) : nil,
                            themeColor: theme.accentColor,
                            onDoubleClick: { withAnimation { editingTask = task } },
                            onQuickArchive: { withAnimation { manager.quickArchive(task: task) } },
                            onStartFocus: { if manager.focusTask != nil { withAnimation { showFocusConflictAlert = true } } else { withAnimation { _ = manager.setAsFocus(task: task) } } }
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .transition(.taskDropIn)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.clear)
            .clipped()
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: manager.inboxTasks)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(opacityMain))
    }
}
