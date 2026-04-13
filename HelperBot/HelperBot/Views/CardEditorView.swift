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
    @Namespace private var editorNamespace

    enum EditorMode { case text, draw }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                cardPreview
                settingsPanel
                modeBar
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadState)
    }

    private var cardPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: selectedColor) ?? Color(.systemGray6))

            if mode == .text {
                TextEditor(text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .focused($textFocused)
            } else {
                DrawingCanvasView(canvasView: $canvasView)
                    .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 300)
    }

    private var settingsPanel: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Цвет карточки")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(CardColor.allCases, id: \.hex) { c in
                            Circle()
                                .fill(c.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.label), lineWidth: selectedColor == c.hex ? 2.5 : 0)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedColor = c.hex
                                    }
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Категория")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(defaultCategories, id: \.self) { cat in
                            Text(cat)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .glassEffect(
                                    selectedCategory == cat
                                        ? .regular.tint(.primary)
                                        : .regular,
                                    in: .capsule
                                )
                                .foregroundColor(selectedCategory == cat ? .white : .primary)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedCategory = selectedCategory == cat ? "" : cat
                                    }
                                }
                        }
                    }
                }
            }
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
    }

    private var modeBar: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                Button { mode = .text; textFocused = true } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "textformat")
                            .font(.system(size: 16, weight: .medium))
                        Text("Текст")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .glassEffect(mode == .text ? .regular.interactive() : .regular, in: .rect(cornerRadius: 16))

                Button { mode = .draw; textFocused = false } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 16, weight: .medium))
                        Text("Рисовать")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .glassEffect(mode == .draw ? .regular.interactive() : .regular, in: .rect(cornerRadius: 16))

                Button(action: save) {
                    VStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Сохранить")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .glassEffect(.regular.interactive().tint(.green.opacity(0.4)), in: .rect(cornerRadius: 16))
            }
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
