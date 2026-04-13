import SwiftUI

struct CardGridView: View {
    @EnvironmentObject var store: ChecklistStore
    @State private var editorTask: TaskItem?
    @State private var editorDefaultCard: DefaultCard?
    @State private var showEditor = false
    @State private var inputText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    header.padding(.bottom, 8)

                    if store.allTasks.isEmpty {
                        defaultGrid
                    } else {
                        taskGrid
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
            editorSheet
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

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.top, 8)
    }

    private var defaultGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(defaultCards) { card in
                DefaultCardView(card: card)
                    .onTapGesture {
                        editorDefaultCard = card
                        editorTask = nil
                        showEditor = true
                    }
            }
        }
    }

    private var taskGrid: some View {
        VStack(spacing: 10) {
            ForEach(store.lists) { list in
                if store.lists.count > 1 {
                    Text("Список #\(listIndex(list) + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(list.tasks) { task in
                        CardView(task: task)
                            .onTapGesture {
                                editorTask = task
                                editorDefaultCard = nil
                                showEditor = true
                            }
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
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

            Button(action: submitQuickAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(.label), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.clear)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func submitQuickAdd() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task {
            await store.addTask(text: text, color: TaskItem.defaultColor, category: "", drawing: "")
        }
    }

    @ViewBuilder
    private var editorSheet: some View {
        if let task = editorTask {
            CardEditorView(existingTask: task, defaultCard: nil)
                .environmentObject(store)
        } else if let card = editorDefaultCard {
            CardEditorView(existingTask: nil, defaultCard: card)
                .environmentObject(store)
        }
    }

    private func listIndex(_ list: ChecklistGroup) -> Int {
        store.lists.firstIndex(where: { $0.id == list.id }) ?? 0
    }
}
