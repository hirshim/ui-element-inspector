import SwiftUI

struct ElementTreeView: View {
  let rootElement: AccessibilityElement?;
  let selectedElement: AccessibilityElement?;
  let onSelect: (AccessibilityElement) -> Void;
  let onHover: ((AccessibilityElement?) -> Void)?;

  var body: some View {
    if let root = rootElement {
      List(selection: Binding(
        get: { selectedElement?.id },
        set: { id in
          if let el = findElement(id: id, in: root) {
            onSelect(el);
          }
        }
      )) {
        OutlineGroup(root.children, id: \.id, children: \.optionalChildren) { element in
          ElementTreeNodeView(element: element, isSelected: element.id == selectedElement?.id)
            .tag(element.id)
            .onHover { isHovered in
              onHover?(isHovered ? element : nil);
            };
        }
      }
    } else {
      ContentUnavailableView("要素なし", systemImage: "rectangle.dashed");
    }
  }

  private func findElement(id: UUID?, in element: AccessibilityElement) -> AccessibilityElement? {
    guard let id else { return nil; }
    if element.id == id { return element; }
    for child in element.children {
      if let found = findElement(id: id, in: child) {
        return found;
      }
    }
    return nil;
  }
}
