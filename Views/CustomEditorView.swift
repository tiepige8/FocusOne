import SwiftUI

struct CustomEditorView: View {
    let task: TaskItem; let isCompletingFlow: Bool; @ObservedObject var manager: TaskManager; var onClose: () -> Void
    @State private var editedTitle: String = ""; @State private var editedContent: String = ""; @State private var editedTags: [String] = []; @State private var newTagText: String = ""
    var suggestedTags: [String] { manager.getSuggestedTags(title: editedTitle, content: editedContent, currentTags: editedTags) }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isCompletingFlow ? "完成任务" : "编辑笔记").font(.headline).foregroundColor(.secondary)
                Spacer()
                if !isCompletingFlow { Button(action: onClose) { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary).padding(6).background(Color.primary.opacity(0.05)).clipShape(Circle()) }.buttonStyle(.plain) }
            }.padding(24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TextField("无标题", text: $editedTitle).font(.system(size: 24, weight: .bold)).textFieldStyle(.plain)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Image(systemName: "number").font(.caption).foregroundColor(.secondary); TextField("添加标签...", text: $newTagText).textFieldStyle(.plain).onSubmit { if !newTagText.isEmpty { editedTags.append(newTagText); newTagText = "" } } }
                        if !editedTags.isEmpty { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(editedTags, id: \.self) { tag in Text(tag).font(.caption).padding(6).background(manager.currentTheme.secondaryColor).foregroundColor(manager.currentTheme.accentColor).cornerRadius(8).onTapGesture { editedTags.removeAll { $0 == tag } } } } } }
                        if !suggestedTags.isEmpty { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(suggestedTags.prefix(5), id: \.self) { tag in Button(action: { editedTags.append(tag) }) { Text(tag).font(.caption).padding(6).background(Color.primary.opacity(0.05)).foregroundColor(.secondary).cornerRadius(8) }.buttonStyle(.plain) } } } }
                    }
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        if editedContent.isEmpty { Text("输入笔记...").foregroundColor(.secondary.opacity(0.5)).padding(16) }
                        // 这里调用 transparentScrolling，定义在 AnimationExtensions.swift 里
                        TextEditor(text: $editedContent).font(.body).padding(12).transparentScrolling()
                    }.frame(minHeight: 200)
                    HStack { Text("创建于 " + manager.dateFormatter.string(from: task.creationDate)); Spacer() }.font(.caption).foregroundColor(.secondary)
                }.padding(.horizontal, 24).padding(.bottom, 24)
            }
            
            HStack {
                if isCompletingFlow { Button("取消") { onClose() }.buttonStyle(.plain).padding().overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2))) }
                Button(action: { manager.updateTaskDetail(task: task, newTitle: editedTitle, newContent: editedContent, newTags: editedTags); if isCompletingFlow { manager.completeTask(task: task) }; onClose() }) { Text(isCompletingFlow ? "确认完成" : "保存").bold().foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(manager.currentTheme.accentColor).cornerRadius(8) }.buttonStyle(.plain).disabled(editedTitle.isEmpty)
            }.padding(24).background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor)).cornerRadius(16).shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear { editedTitle = task.title; editedContent = task.content; editedTags = task.tags }
    }
}
// 【注意】这里删除了 extension View，移到了 AnimationExtensions.swift
