import SwiftUI

struct CategoryDetailView: View {
    @EnvironmentObject var store: ChecklistStore
    @Environment(\.dismiss) private var dismiss

    let category: String
    @State private var showEditor = false
    @State private var editorTask: TaskItem?

    var tasks: [TaskItem] {
        store.allTasks.filter { task in
            let normalized = task.category.isEmpty ? "Без категории" : task.category
            return normalized == category
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            onToggle: { Task { await store.toggleTask(task.id) } },
                            onDelete: { Task { await store.deleteTask(task.id) } }
                        )
                        .onTapGesture {
                            editorTask = task
                            showEditor = true
                        }
                    }

                    if tasks.isEmpty {
                        VStack(spacing: 8) {
                            Text("Пока пусто")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("Добавь задачу в эту категорию")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "#f5f1e8") ?? Color(.systemGroupedBackground))
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorTask = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                if let task = editorTask {
                    CardEditorView(existingTask: task, defaultCard: nil)
                        .environmentObject(store)
                } else {
                    CardEditorView(
                        existingTask: nil,
                        defaultCard: DefaultCard(emoji: "", title: category)
                    )
                    .environmentObject(store)
                }
            }
        }
    }
}
