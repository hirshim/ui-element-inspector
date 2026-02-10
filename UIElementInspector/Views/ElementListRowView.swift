import SwiftUI

struct ElementListRowView: View {
  let element: AccessibilityElement;

  var body: some View {
    HStack {
      Text(element.displayLabel)
        .font(.system(.body, design: .monospaced));

      Spacer();

      if let pos = element.position, let size = element.size {
        Text("(\(Int(pos.x)),\(Int(pos.y))) \(Int(size.width))x\(Int(size.height))")
          .font(.caption)
          .foregroundStyle(.secondary);
      }
    }
    .padding(.leading, CGFloat(element.depth) * 8);
  }
}
