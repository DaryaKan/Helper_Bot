import SwiftUI
import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: String
    var text: String
    var done: Bool
    var color: String
    var category: String
    var drawing: String

    var uiColor: Color {
        Color(hex: color) ?? Color(.systemGray6)
    }

    static let defaultColor = "#f4f4f4"
}

struct ChecklistGroup: Identifiable, Codable {
    let id: String
    var tasks: [TaskItem]
}

struct TasksResponse: Codable {
    let lists: [ChecklistGroup]?
    let error: String?
}

struct TaskMutationResponse: Codable {
    let task: TaskItem?
    let lists: [ChecklistGroup]?
    let error: String?
}

enum CardColor: CaseIterable {
    case gray, yellow, green, blue, pink, purple

    var hex: String {
        switch self {
        case .gray:   return "#f4f4f4"
        case .yellow: return "#f5e6b8"
        case .green:  return "#c8e6c9"
        case .blue:   return "#bbdefb"
        case .pink:   return "#f4d1d1"
        case .purple: return "#e1bee7"
        }
    }

    var color: Color {
        Color(hex: hex) ?? .gray
    }
}

let defaultCategories = ["Покупки", "Заметки", "Работа", "Книги", "Личное"]

struct DefaultCard: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
}

let defaultCards: [DefaultCard] = [
    DefaultCard(emoji: "🛒", title: "Покупки"),
    DefaultCard(emoji: "📝", title: "Заметки"),
    DefaultCard(emoji: "💼", title: "Работа"),
    DefaultCard(emoji: "📚", title: "Книги"),
]

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
