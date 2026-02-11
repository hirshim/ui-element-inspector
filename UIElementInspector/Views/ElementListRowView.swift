import SwiftUI

struct ElementListRowView: View {
  let element: AccessibilityElement;
  @State private var isHovering = false;

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
    .padding(.leading, CGFloat(element.depth) * 8)
    .background(isHovering ? Color.blue.opacity(0.1) : Color.clear)
    .onHover { hovering in
      isHovering = hovering;
    };
  }
}
