import SwiftUI

struct CardView: View {
    let task: TaskItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(task.uiColor)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            if let img = drawingImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.text == "(рисунок)" ? "" : task.text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .strikethrough(task.done)
                    .foregroundStyle(task.done ? .secondary : .primary)
                    .lineLimit(5)

                if !task.category.isEmpty {
                    Text(task.category)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.05), in: Capsule())
                }

                Spacer()

                HStack {
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

                    Spacer()
                }
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(task.done ? 0.6 : 1)
    }

    private var drawingImage: UIImage? {
        guard !task.drawing.isEmpty,
              let commaIdx = task.drawing.firstIndex(of: ",") else { return nil }
        let base64 = String(task.drawing[task.drawing.index(after: commaIdx)...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
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
                Text(card.emoji)
                    .font(.system(size: 32))

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
