//
//  TaskModels.swift
//  FocusNote
//
//  Created by 铁皮鸽 on 2025/11/25.
//

import SwiftUI

struct TaskSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

enum TaskStatus: String, Codable { case inbox, focus, completed }

struct TaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String = ""
    var status: TaskStatus = .inbox
    var creationDate: Date = Date()
    var updateDate: Date = Date()
    var tags: [String] = []
    var isPaused: Bool = false
    var sessions: [TaskSession] = []
    
    func currentSessionDuration() -> TimeInterval {
        if status == .focus, let last = sessions.last, last.endTime == nil {
            return Date().timeIntervalSince(last.startTime)
        } else {
            return 0
        }
    }
    
    func totalDuration() -> TimeInterval {
        return sessions.reduce(0) { $0 + $1.duration }
    }
}

struct AppDataV6: Codable {
    let tasks: [TaskItem]
    let allTags: Set<String>
}
