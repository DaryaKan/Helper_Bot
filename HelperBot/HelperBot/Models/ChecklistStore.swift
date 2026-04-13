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
        if let result = await api.getTasks() {
            lists = result
        }
    }

    func addTask(text: String, color: String, category: String, drawing: String) async {
        if let result = await api.addTask(text: text, color: color, category: category, drawing: drawing) {
            lists = result
        }
    }

    func toggleTask(_ taskId: String) async {
        if let result = await api.toggleTask(taskId: taskId) {
            lists = result
        }
    }

    func updateTask(taskId: String, text: String, color: String, category: String, drawing: String) async {
        if let result = await api.updateTask(taskId: taskId, text: text, color: color, category: category, drawing: drawing) {
            lists = result
        }
    }

    func deleteTask(_ taskId: String) async {
        if let result = await api.deleteTask(taskId: taskId) {
            lists = result
        }
    }

    func task(byId id: String) -> TaskItem? {
        allTasks.first { $0.id == id }
    }
}
