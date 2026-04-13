import SwiftUI
import Combine

@MainActor
final class ChecklistStore: ObservableObject {
    @Published var lists: [ChecklistGroup] = []
    @Published var isLoading = false

    private let api = APIClient.shared

    var allTasks: [TaskItem] {
        lists.flatMap { $0.tasks }
    }

    var totalCount: Int { allTasks.count }
    var doneCount: Int { allTasks.filter(\.done).count }

    func fetchTasks() async {
        isLoading = true
        defer { isLoading = false }

        if api.isLocalOnlyMode {
            if let loaded = LocalTaskStore.load() {
                lists = loaded
            }
            return
        }

        if let result = await api.getTasks() {
            lists = result
            LocalTaskStore.save(result)
        } else if let loaded = LocalTaskStore.load() {
            lists = loaded
        }
    }

    func addTask(text: String, color: String, category: String, drawing: String) async {
        if api.isLocalOnlyMode {
            let next = LocalTaskStore.addTask(to: lists, text: text, color: color, category: category, drawing: drawing)
            lists = next
            LocalTaskStore.save(next)
            return
        }
        if let result = await api.addTask(text: text, color: color, category: category, drawing: drawing) {
            lists = result
            LocalTaskStore.save(result)
        }
    }

    func toggleTask(_ taskId: String) async {
        if api.isLocalOnlyMode {
            let next = LocalTaskStore.toggleTask(taskId: taskId, in: lists)
            lists = next
            LocalTaskStore.save(next)
            return
        }
        if let result = await api.toggleTask(taskId: taskId) {
            lists = result
            LocalTaskStore.save(result)
        }
    }

    func updateTask(taskId: String, text: String, color: String, category: String, drawing: String) async {
        if api.isLocalOnlyMode {
            let next = LocalTaskStore.updateTask(
                taskId: taskId,
                text: text,
                color: color,
                category: category,
                drawing: drawing,
                in: lists
            )
            lists = next
            LocalTaskStore.save(next)
            return
        }
        if let result = await api.updateTask(taskId: taskId, text: text, color: color, category: category, drawing: drawing) {
            lists = result
            LocalTaskStore.save(result)
        }
    }

    func deleteTask(_ taskId: String) async {
        if api.isLocalOnlyMode {
            let next = LocalTaskStore.deleteTask(taskId: taskId, in: lists)
            lists = next
            LocalTaskStore.save(next)
            return
        }
        if let result = await api.deleteTask(taskId: taskId) {
            lists = result
            LocalTaskStore.save(result)
        }
    }

    func task(byId id: String) -> TaskItem? {
        allTasks.first { $0.id == id }
    }
}
