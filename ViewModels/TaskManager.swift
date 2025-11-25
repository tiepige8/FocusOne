import SwiftUI
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var allTags: Set<String> = []
    @Published var currentTime = Date()
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false
    
    @AppStorage("selectedThemeIndex") var selectedThemeIndex: Int = 0
    @Published var customBookmarkDataStr: String {
        didSet { UserDefaults.standard.set(customBookmarkDataStr, forKey: "customBookmarkDataStr") }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    let shortDateFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MM-dd HH:mm"; return f }()
    let dateFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"; return f }()
    private var beijingTimeFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; f.timeZone = TimeZone(identifier: "Asia/Shanghai"); return f }()
    
    init() {
        self.customBookmarkDataStr = UserDefaults.standard.string(forKey: "customBookmarkDataStr") ?? ""
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in self.currentTime = Date() }
        loadData()
        self.$tasks.sink { _ in self.saveData() }.store(in: &cancellables)
        self.$allTags.sink { _ in self.saveData() }.store(in: &cancellables)
    }
    
    var currentTheme: AppTheme { if selectedThemeIndex >= 0 && selectedThemeIndex < AppTheme.presets.count { return AppTheme.presets[selectedThemeIndex] } else { return AppTheme.presets[0] } }
    private var customBookmarkData: Data { Data(base64Encoded: customBookmarkDataStr) ?? Data() }
    
    var dataFileURL: URL {
        // 【修改】文件名改为 focusone_data.json
        let fileName = "focusone_data.json"
        if !customBookmarkData.isEmpty {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: customBookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if url.startAccessingSecurityScopedResource() { return url.appendingPathComponent(fileName) }
            } catch { print("解析失败: \(error)") }
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    var currentDisplayPath: String {
        if customBookmarkData.isEmpty { return "默认 (文稿文件夹)" }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: customBookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) { return url.path }
        return "自定义路径"
    }
    
    func updateDataLocation(to newFolderURL: URL) {
        let oldFileURL = self.dataFileURL
        // 【修改】文件名同步更新
        let newFileURL = newFolderURL.appendingPathComponent("focusone_data.json")
        do {
            let bookmark = try newFolderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            if FileManager.default.fileExists(atPath: oldFileURL.path) && !FileManager.default.fileExists(atPath: newFileURL.path) {
                try FileManager.default.moveItem(at: oldFileURL, to: newFileURL)
            }
            self.customBookmarkDataStr = bookmark.base64EncodedString()
            self.saveData()
            self.showToast(message: "位置已更新")
        } catch { self.showToast(message: "设置失败: \(error.localizedDescription)") }
    }
    
    func saveData() { do { let data = try JSONEncoder().encode(AppDataV6(tasks: tasks, allTags: allTags)); try data.write(to: dataFileURL) } catch { print("保存失败: \(error)") } }
    
    func loadData() { do { let data = try Data(contentsOf: dataFileURL); let appData = try JSONDecoder().decode(AppDataV6.self, from: data); self.tasks = appData.tasks; self.allTags = appData.allTags } catch { attemptLoadV5Data() } }
    
    private func attemptLoadV5Data() {
        // 尝试从旧版 FocusNote 数据迁移
        let v5URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("focusnote_data_v6.json")
        do {
            let data = try Data(contentsOf: v5URL)
            let appData = try JSONDecoder().decode(AppDataV6.self, from: data)
            self.tasks = appData.tasks
            self.allTags = appData.allTags
            saveData() // 迁移到新文件 focusone_data.json
            print("已从 FocusNote 迁移数据")
        } catch { }
    }
    
    var focusTask: TaskItem? { tasks.first { $0.status == .focus } }
    var inboxTasks: [TaskItem] { tasks.filter { $0.status == .inbox }.sorted { if $0.isPaused != $1.isPaused { return $0.isPaused } else { return $0.updateDate > $1.updateDate } } }
    var historyTasks: [TaskItem] { tasks.filter { $0.status == .completed }.sorted { ($0.sessions.last?.endTime ?? $0.updateDate) > ($1.sessions.last?.endTime ?? $1.updateDate) } }
    var totalHistoryDuration: TimeInterval { historyTasks.reduce(0) { $0 + $1.totalDuration() } }
    
    func addTask(title: String) { tasks.append(TaskItem(title: title)) }
    func updateTaskDetail(task: TaskItem, newTitle: String, newContent: String, newTags: [String]) { if let index = tasks.firstIndex(where: { $0.id == task.id }) { tasks[index].title = newTitle; tasks[index].content = newContent; tasks[index].tags = newTags; tasks[index].updateDate = Date(); newTags.forEach { allTags.insert($0) } } }
    func getSuggestedTags(title: String, content: String, currentTags: [String]) -> [String] { let combined = (title + " " + content).lowercased(); let available = allTags.filter { !currentTags.contains($0) }; return available.sorted { let r1 = combined.contains($0.lowercased()); let r2 = combined.contains($1.lowercased()); if r1 && !r2 { return true }; if !r1 && r2 { return false }; return $0 < $1 } }
    
    func setAsFocus(task: TaskItem) -> Bool {
        if focusTask != nil { return false }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { tasks[index].status = .focus; tasks[index].isPaused = false; tasks[index].sessions.append(TaskSession(startTime: Date())); tasks[index].updateDate = Date(); return true }
        return false
    }
    
    func doLater(task: TaskItem) {
        let pausedCount = tasks.filter { $0.status == .inbox && $0.isPaused }.count
        if pausedCount >= 6 { showToast(message: "你待处理的事情太多了，先解决1个吧"); return }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { if var last = tasks[index].sessions.last, last.endTime == nil { last.endTime = Date(); tasks[index].sessions[tasks[index].sessions.count - 1] = last }; tasks[index].status = .inbox; tasks[index].isPaused = true; tasks[index].updateDate = Date() }
    }
    
    func completeTask(task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { if var last = tasks[index].sessions.last, last.endTime == nil { last.endTime = Date(); tasks[index].sessions[tasks[index].sessions.count - 1] = last }; tasks[index].status = .completed; tasks[index].isPaused = false; tasks[index].updateDate = Date(); showToast(message: "任务已完成") }
    }
    
    func quickArchive(task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { if var last = tasks[index].sessions.last, last.endTime == nil { last.endTime = Date(); tasks[index].sessions[tasks[index].sessions.count - 1] = last }; tasks[index].status = .completed; tasks[index].isPaused = false; tasks[index].updateDate = Date(); showToast(message: "已快速归档") }
    }
    
    func copyHistoryToMarkdown() {
        var md = "# 专注报告\n\n- 总任务: \(historyTasks.count)\n- 总时长: \(formatDuration(totalHistoryDuration))\n\n"; for task in historyTasks { md += "### \(task.title)\n- 耗时: \(formatDuration(task.totalDuration()))\n" + (task.content.isEmpty ? "" : "> \(task.content)\n") + "\n" }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(md, forType: .string); showToast(message: "已复制 Markdown")
    }
    
    func showToast(message: String) { self.toastMessage = message; withAnimation { self.showToast = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { self.showToast = false } } }
    func formatDuration(_ duration: TimeInterval) -> String { let f = DateComponentsFormatter(); f.allowedUnits = [.hour, .minute, .second]; f.unitsStyle = .positional; f.zeroFormattingBehavior = .pad; return f.string(from: duration) ?? "00:00" }
    func getBeijingTimeString() -> String { return beijingTimeFormatter.string(from: currentTime) }
}
