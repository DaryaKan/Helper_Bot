import SwiftUI

struct CategoryGroup: Identifiable {
    let id: String
    let category: String
    let tasks: [TaskItem]
    let color: Color
}

struct CardGridView: View {
    @EnvironmentObject var store: ChecklistStore
    @State private var showEditor = false
    @State private var editorDefaultCard: DefaultCard?
    @State private var selectedCategory: String?
    @State private var showCategoryDetail = false
    @State private var inputText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var categoryGroups: [CategoryGroup] {
        var groups: [String: [TaskItem]] = [:]
        for task in store.allTasks {
            let cat = task.category.isEmpty ? "Без категории" : task.category
            groups[cat, default: []].append(task)
        }
        return groups.map { key, tasks in
            let color = tasks.first?.uiColor ?? Color(.systemGray6)
            return CategoryGroup(id: key, category: key, tasks: tasks, color: color)
        }.sorted { $0.category < $1.category }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    header.padding(.bottom, 8)

                    if store.allTasks.isEmpty {
                        defaultGrid
                    } else {
                        stackGrid
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            inputBar
        }
        .background(Color(hex: "#f5f1e8") ?? Color(.systemGray6))
        .sheet(isPresented: $showEditor) {
            if let card = editorDefaultCard {
                CardEditorView(existingTask: nil, defaultCard: card)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showCategoryDetail) {
            if let cat = selectedCategory {
                CategoryDetailView(category: cat)
                    .environmentObject(store)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Мои задачи")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                if store.totalCount > 0 {
                    Text("\(store.totalCount) задач · \(store.doneCount) выполнено")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var defaultGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(defaultCards) { card in
                DefaultCardView(card: card)
                    .onTapGesture {
                        editorDefaultCard = card
                        showEditor = true
                    }
            }
        }
    }

    private var stackGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(categoryGroups) { group in
                CategoryStackView(
                    category: group.category,
                    tasks: group.tasks,
                    color: group.color
                )
                .onTapGesture {
                    selectedCategory = group.category
                    showCategoryDetail = true
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 15))

            TextField("Новая задача...", text: $inputText)
                .font(.system(size: 15, design: .rounded))
                .onSubmit { submitQuickAdd() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func submitQuickAdd() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task {
            await store.addTask(text: text, color: TaskItem.defaultColor, category: "", drawing: "")
        }
    }
}
