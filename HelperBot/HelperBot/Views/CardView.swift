import SwiftUI

struct CategoryStackView: View {
    let category: String
    let tasks: [TaskItem]
    let color: Color

    var body: some View {
        ZStack {
            if tasks.count >= 3 {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.5))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .offset(y: -8)
                    .scaleEffect(0.92)
            }

            if tasks.count >= 2 {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.75))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                    .offset(y: -4)
                    .scaleEffect(0.96)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Spacer()

                    Text(category)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    let done = tasks.filter(\.done).count
                    Text("\(tasks.count) задач · \(done) ✓")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct DefaultCardView: View {
    let card: DefaultCard

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Spacer()

                Text(card.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                Text("0 задач")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.done ? Color.clear : Color.black.opacity(0.12), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if task.done {
                        Circle()
                            .fill(Color(.label))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .strikethrough(task.done)
                    .foregroundStyle(task.done ? .secondary : .primary)

                if let img = drawingImage(task) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(task.uiColor)
        )
        .opacity(task.done ? 0.6 : 1)
    }

    private func drawingImage(_ task: TaskItem) -> UIImage? {
        guard !task.drawing.isEmpty,
              let commaIdx = task.drawing.firstIndex(of: ",") else { return nil }
        let base64 = String(task.drawing[task.drawing.index(after: commaIdx)...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}
