import SwiftUI

struct CardView: View {
    let task: TaskItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(task.uiColor)

            if let img = drawingImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.text == "(рисунок)" ? "" : task.text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .strikethrough(task.done)
                    .foregroundStyle(task.done ? .secondary : .primary)
                    .lineLimit(4)

                if !task.category.isEmpty {
                    Text(task.category)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack {
                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(task.done ? .primary : .secondary)
                        .padding(4)
                        .glassEffect(.regular, in: .circle)

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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#f4f4f4") ?? .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.emoji)
                    .font(.system(size: 28))

                Text(card.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))

                Text("0 задач")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
