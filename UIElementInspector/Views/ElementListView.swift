import SwiftUI

struct ElementListView: View {
  let elements: [AccessibilityElement];
  let selectedElement: AccessibilityElement?;
  let onSelect: (AccessibilityElement) -> Void;
  let onHover: ((AccessibilityElement?) -> Void)?;

  var body: some View {
    List(elements, id: \.id, selection: Binding(
      get: { selectedElement?.id },
      set: { id in
        if let el = elements.first(where: { $0.id == id }) {
          onSelect(el);
        }
      }
    )) { element in
      ElementListRowView(element: element)
        .tag(element.id)
        .onHover { isHovered in
          onHover?(isHovered ? element : nil);
        };
    }
  }
}
