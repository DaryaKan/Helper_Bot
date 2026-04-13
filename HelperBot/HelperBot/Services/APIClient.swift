import Foundation

final class APIClient {
    static let shared = APIClient()

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://localhost:8080"
    }

    private var initData: String {
        UserDefaults.standard.string(forKey: "telegram_init_data") ?? ""
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async -> Data? {
        guard let url = URL(string: baseURL + path) else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(initData, forHTTPHeaderField: "X-Telegram-Init-Data")
        req.timeoutInterval = 10

        if let body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            return data
        } catch {
            print("[API] \(method) \(path) error: \(error.localizedDescription)")
            return nil
        }
    }

    func getTasks() async -> [ChecklistGroup]? {
        guard let data = await request("/api/tasks") else { return nil }
        return (try? decoder.decode(TasksResponse.self, from: data))?.lists
    }

    func addTask(text: String, color: String, category: String, drawing: String) async -> [ChecklistGroup]? {
        var body: [String: Any] = ["text": text, "color": color, "category": category]
        if !drawing.isEmpty { body["drawing"] = drawing }
        guard let data = await request("/api/tasks/add", method: "POST", body: body) else { return nil }
        return (try? decoder.decode(TaskMutationResponse.self, from: data))?.lists
    }

    func toggleTask(taskId: String) async -> [ChecklistGroup]? {
        guard let data = await request("/api/tasks/toggle", method: "POST", body: ["task_id": taskId]) else { return nil }
        return (try? decoder.decode(TaskMutationResponse.self, from: data))?.lists
    }

    func updateTask(taskId: String, text: String, color: String, category: String, drawing: String) async -> [ChecklistGroup]? {
        var body: [String: Any] = ["task_id": taskId, "text": text, "color": color, "category": category]
        if !drawing.isEmpty { body["drawing"] = drawing }
        guard let data = await request("/api/tasks/update", method: "POST", body: body) else { return nil }
        return (try? decoder.decode(TaskMutationResponse.self, from: data))?.lists
    }

    func deleteTask(taskId: String) async -> [ChecklistGroup]? {
        guard let data = await request("/api/tasks/delete", method: "POST", body: ["task_id": taskId]) else { return nil }
        return (try? decoder.decode(TasksResponse.self, from: data))?.lists
    }
}
