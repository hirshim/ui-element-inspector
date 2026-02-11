import SwiftUI

struct ElementTreeView: View {
  let rootElement: AccessibilityElement?;
  let selectedElement: AccessibilityElement?;
  let onSelect: (AccessibilityElement) -> Void;
  let onHover: ((AccessibilityElement?) -> Void)?;

  @State private var expandedItems: Set<String> = [];

  var body: some View {
    if let root = rootElement {
      List(selection: Binding(
        get: { selectedElement?.id },
        set: { id in
          if let id, let el = findElement(id: id, in: root) {
            onSelect(el);
          }
        }
      )) {
        ForEach(root.children) { element in
          TreeNodeContent(
            element: element,
            selectedElement: selectedElement,
            expandedItems: $expandedItems,
            onHover: onHover
          );
        }
      }
      .onAppear {
        expandToSelected(in: root);
      }
      .onChange(of: selectedElement?.id) { _, _ in
        expandToSelected(in: root);
      };
    } else {
      ContentUnavailableView("要素なし", systemImage: "rectangle.dashed");
    }
  }

  private func expandToSelected(in root: AccessibilityElement) {
    guard let selected = selectedElement else { return; }
    if let ancestors = findAncestorIDs(of: selected, in: root) {
      expandedItems.formUnion(ancestors);
    }
  }

  private func findAncestorIDs(of target: AccessibilityElement, in node: AccessibilityElement) -> Set<String>? {
    if node == target { return Set(); }
    for child in node.children {
      if let ancestors = findAncestorIDs(of: target, in: child) {
        return ancestors.union([node.stableID]);
      }
    }
    return nil;
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

private struct TreeNodeContent: View {
  let element: AccessibilityElement;
  let selectedElement: AccessibilityElement?;
  @Binding var expandedItems: Set<String>;
  let onHover: ((AccessibilityElement?) -> Void)?;

  var body: some View {
    if element.children.isEmpty {
      ElementTreeNodeView(element: element, isSelected: element.id == selectedElement?.id)
        .tag(element.id)
        .onHover { isHovered in
          onHover?(isHovered ? element : nil);
        };
    } else {
      DisclosureGroup(
        isExpanded: Binding(
          get: { expandedItems.contains(element.stableID) },
          set: { isExpanded in
            if isExpanded {
              expandedItems.insert(element.stableID);
            } else {
              expandedItems.remove(element.stableID);
            }
          }
        )
      ) {
        ForEach(element.children) { child in
          TreeNodeContent(
            element: child,
            selectedElement: selectedElement,
            expandedItems: $expandedItems,
            onHover: onHover
          );
        }
      } label: {
        ElementTreeNodeView(element: element, isSelected: element.id == selectedElement?.id)
          .tag(element.id)
          .onHover { isHovered in
            onHover?(isHovered ? element : nil);
          };
      }
    }
  }
}
