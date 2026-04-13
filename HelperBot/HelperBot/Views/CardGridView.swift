import SwiftUI

struct CardGridView: View {
    @EnvironmentObject var store: ChecklistStore
    @State private var editorTask: TaskItem?
    @State private var editorDefaultCard: DefaultCard?
    @State private var showEditor = false
    @Namespace private var cardNamespace

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                GlassEffectContainer {
                    if store.allTasks.isEmpty {
                        defaultGrid
                    } else {
                        taskGrid
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }

            inputBar
        }
        .background(Color.white)
        .sheet(isPresented: $showEditor) {
            editorSheet
        }
    }

    private var defaultGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(defaultCards.enumerated()), id: \.element.id) { idx, card in
                DefaultCardView(card: card)
                    .glassEffectID("default-\(idx)", in: cardNamespace)
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
                            .glassEffectID("task-\(task.id)", in: cardNamespace)
                            .onTapGesture {
                                withAnimation(.bouncy) {
                                    editorTask = task
                                    editorDefaultCard = nil
                                    showEditor = true
                                }
                            }
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        GlassEffectContainer {
            HStack(spacing: 10) {
                TextField("Добавить задачу...", text: $inputText)
                    .font(.system(size: 15, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .glassEffect(.regular, in: .capsule)
                    .onSubmit { submitQuickAdd() }

                Button(action: submitQuickAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                }
                .glassEffect(.regular.interactive().tint(.primary), in: .circle)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @State private var inputText = ""

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
