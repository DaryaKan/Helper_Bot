import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

extension PKCanvasView {
    func toBase64PNG(size: CGSize) -> String {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            drawing.image(from: CGRect(origin: .zero, size: size), scale: UIScreen.main.scale)
                .draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = image.pngData() else { return "" }
        return "data:image/png;base64," + data.base64EncodedString()
    }

    func loadFromBase64(_ dataURL: String) {
        guard !dataURL.isEmpty,
              let commaIdx = dataURL.firstIndex(of: ",") else { return }
        let base64 = String(dataURL[dataURL.index(after: commaIdx)...])
        guard let data = Data(base64Encoded: base64),
              let image = UIImage(data: data) else { return }

        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        _ = renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: bounds.size))
        }
    }
}
