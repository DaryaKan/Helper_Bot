import Foundation

/// Persists checklist data on device when the app runs without Telegram WebApp `initData`
/// (native iOS build cannot call the authenticated API).
enum LocalTaskStore {
    private static let storageKey = "local_checklist_lists_v1"
    private static let maxTasksPerList = 10

    static func load() -> [ChecklistGroup]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode([ChecklistGroup].self, from: data)
    }

    static func save(_ lists: [ChecklistGroup]) {
        guard let data = try? JSONEncoder().encode(lists) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func addTask(
        to lists: [ChecklistGroup],
        text: String,
        color: String,
        category: String,
        drawing: String
    ) -> [ChecklistGroup] {
        let task = TaskItem(
            id: String(UUID().uuidString.prefix(8)),
            text: text,
            done: false,
            color: color,
            category: category,
            drawing: drawing
        )
        var result = lists
        if result.isEmpty {
            result.append(ChecklistGroup(id: String(UUID().uuidString.prefix(8)), tasks: [task]))
            return result
        }
        var last = result.count - 1
        if result[last].tasks.count >= maxTasksPerList {
            result.append(ChecklistGroup(id: String(UUID().uuidString.prefix(8)), tasks: [task]))
        } else {
            var tasks = result[last].tasks
            tasks.append(task)
            result[last] = ChecklistGroup(id: result[last].id, tasks: tasks)
        }
        return result
    }

    static func toggleTask(taskId: String, in lists: [ChecklistGroup]) -> [ChecklistGroup] {
        mutate(lists) { task in
            if task.id == taskId {
                task.done.toggle()
                return true
            }
            return false
        }
    }

    static func updateTask(
        taskId: String,
        text: String,
        color: String,
        category: String,
        drawing: String,
        in lists: [ChecklistGroup]
    ) -> [ChecklistGroup] {
        mutate(lists) { task in
            guard task.id == taskId else { return false }
            task.text = text
            task.color = color
            task.category = category
            task.drawing = drawing
            return true
        }
    }

    static func deleteTask(taskId: String, in lists: [ChecklistGroup]) -> [ChecklistGroup] {
        var result = lists
        for i in result.indices {
            result[i].tasks.removeAll { $0.id == taskId }
        }
        result.removeAll { $0.tasks.isEmpty }
        return result
    }

    private static func mutate(_ lists: [ChecklistGroup], _ body: (inout TaskItem) -> Bool) -> [ChecklistGroup] {
        var result = lists
        for li in result.indices {
            for ti in result[li].tasks.indices {
                if body(&result[li].tasks[ti]) {
                    return result
                }
            }
        }
        return result
    }
}
