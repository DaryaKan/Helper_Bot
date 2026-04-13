import SwiftUI
import PencilKit

struct CardEditorView: View {
    @EnvironmentObject var store: ChecklistStore
    @Environment(\.dismiss) private var dismiss

    let existingTask: TaskItem?
    let defaultCard: DefaultCard?

    @State private var text: String = ""
    @State private var selectedColor: String = TaskItem.defaultColor
    @State private var selectedCategory: String = ""
    @State private var mode: EditorMode = .text
    @State private var canvasView = PKCanvasView()
    @FocusState private var textFocused: Bool

    enum EditorMode { case text, draw }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cardPreview
                    settingsPanel
                }
                .padding(20)
            }
            .background(Color(hex: "#f5f1e8") ?? Color(.systemGroupedBackground))
            .navigationTitle(existingTask != nil ? "Редактировать" : "Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear(perform: loadState)
    }

    private var cardPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: selectedColor) ?? Color(.systemGray6))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            if mode == .text {
                TextEditor(text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .focused($textFocused)
            } else {
                DrawingCanvasView(canvasView: $canvasView)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Цвет карточки", systemImage: "paintpalette")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(CardColor.allCases, id: \.hex) { c in
                        Circle()
                            .fill(c.color)
                            .frame(width: 36, height: 36)
                            .shadow(color: c.color.opacity(0.4), radius: 4, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color(.label), lineWidth: selectedColor == c.hex ? 2.5 : 0)
                                    .padding(-2)
                            )
                            .scaleEffect(selectedColor == c.hex ? 1.1 : 1)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = c.hex
                                }
                            }
                    }
                }
            }
            .padding(18)

            Divider().padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 12) {
                Label("Категория", systemImage: "tag")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(defaultCategories, id: \.self) { cat in
                        Text(cat)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? Color(.label) : Color(.systemGray6))
                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                            .clipShape(Capsule())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = selectedCategory == cat ? "" : cat
                                }
                            }
                    }
                }
            }
            .padding(18)

            Divider().padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 12) {
                Label("Режим", systemImage: "pencil.and.scribble")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    modeButton(title: "Текст", icon: "textformat", isActive: mode == .text) {
                        mode = .text; textFocused = true
                    }
                    modeButton(title: "Рисовать", icon: "pencil.tip", isActive: mode == .draw) {
                        mode = .draw; textFocused = false
                    }
                }
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    private func modeButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color(.label) : Color(.systemGray6))
            .foregroundColor(isActive ? .white : .primary)
            .clipShape(Capsule())
        }
    }

    private func loadState() {
        if let task = existingTask {
            text = task.text == "(рисунок)" ? "" : task.text
            selectedColor = task.color
            selectedCategory = task.category
            if !task.drawing.isEmpty { mode = .draw }
        } else if let card = defaultCard {
            selectedCategory = card.title
        }
        if mode == .text { textFocused = true }
    }

    private func save() {
        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let drawingData = canvasView.drawing.strokes.isEmpty ? "" : canvasView.toBase64PNG(size: CGSize(width: 300, height: 300))
        let saveText = finalText.isEmpty && !drawingData.isEmpty ? "(рисунок)" : finalText
        guard !saveText.isEmpty else { return }

        Task {
            if let existing = existingTask {
                await store.updateTask(taskId: existing.id, text: saveText, color: selectedColor, category: selectedCategory, drawing: drawingData)
            } else {
                await store.addTask(text: saveText, color: selectedColor, category: selectedCategory, drawing: drawingData)
            }
            dismiss()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }
        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
