import SwiftUI
import Combine

// 【注意】这里删除了 AnyTransition 的扩展代码，因为已经在 AnimationExtensions.swift 里有了

// --- 3. 主入口 ---
struct ContentView: View {
    @ObservedObject var manager: TaskManager
    
    @State private var newTaskTitle: String = ""
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var isMiniMode = false
    
    @AppStorage("opacityMain") private var opacityMain: Double = 1.0
    @AppStorage("opacityMiniBar") private var opacityMiniBar: Double = 0.2
    @AppStorage("opacityMiniContent") private var opacityMiniContent: Double = 0.8
    
    @State private var editingTask: TaskItem? = nil
    @State private var isCompletingFlow: Bool = false
    @State private var showFocusConflictAlert = false
    
    var isModalOpen: Bool { showHistory || editingTask != nil || showFocusConflictAlert || showSettings }
    
    var body: some View {
        ZStack {
            Group {
                if isMiniMode {
                    MiniFocusView(
                        manager: manager,
                        editingTask: $editingTask,
                        isCompletingFlow: $isCompletingFlow,
                        barOpacity: opacityMiniBar,
                        contentOpacity: opacityMiniContent
                    )
                    .frame(width: 180, height: 110)
                } else {
                    FullView(
                        manager: manager,
                        newTaskTitle: $newTaskTitle,
                        showHistory: $showHistory,
                        showSettings: $showSettings,
                        opacityMain: $opacityMain,
                        opacityMiniBar: $opacityMiniBar,
                        opacityMiniContent: $opacityMiniContent,
                        onEnterMiniMode: { enterMiniMode() },
                        editingTask: $editingTask,
                        isCompletingFlow: $isCompletingFlow,
                        showFocusConflictAlert: $showFocusConflictAlert
                    )
                    .background(Color(nsColor: .windowBackgroundColor).opacity(opacityMain))
                }
            }
            .disabled(isModalOpen)
            
            // --- 弹窗层级 ---
            if showHistory {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { withAnimation { showHistory = false } }
                HistoryView(manager: manager) { withAnimation { showHistory = false } }
                    .frame(width: 340, height: 500)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(2)
            }
            
            if let task = editingTask {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { if !isCompletingFlow { withAnimation { editingTask = nil } } }
                CustomEditorView(task: task, isCompletingFlow: isCompletingFlow, manager: manager) {
                    withAnimation { editingTask = nil; isCompletingFlow = false }
                }
                .padding(12)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(3)
            }
            
            if showFocusConflictAlert {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { withAnimation { showFocusConflictAlert = false } }
                CustomAlertView(title: "无法开始", message: "每次只能有一个专注中的任务。\n请先完成或稍后当前任务。", buttonText: "知道了") { withAnimation { showFocusConflictAlert = false } }
                .zIndex(4)
            }
            
            if showSettings {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { withAnimation { showSettings = false } }
                SettingsView(
                    manager: manager,
                    opacityMain: $opacityMain,
                    opacityMiniContent: $opacityMiniContent,
                    onClose: { withAnimation { showSettings = false } }
                )
                .transition(.slideIn)
                .zIndex(5)
            }
            
            if manager.showToast, let msg = manager.toastMessage {
                VStack { Spacer(); Text(msg).font(.system(size: 13)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10).background(Color.black.opacity(0.8)).cornerRadius(20).padding(.bottom, 20) }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(6)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExpandWindow"))) { _ in withAnimation(.spring()) { isMiniMode = false } }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CollapseWindow"))) { _ in withAnimation(.spring()) { isMiniMode = true } }
        .onChange(of: isModalOpen) { newValue in
            if newValue {
                NotificationCenter.default.post(name: NSNotification.Name("ModalOpened"), object: nil)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name("ModalClosed"), object: nil)
            }
        }
    }
    
    func enterMiniMode() { withAnimation { isMiniMode = true }; NotificationCenter.default.post(name: NSNotification.Name("EnterMiniMode"), object: nil) }
}
