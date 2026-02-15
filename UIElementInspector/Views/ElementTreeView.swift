import SwiftUI

struct ElementTreeView: View {
  let rootElement: AccessibilityElement?;
  let selectedElement: AccessibilityElement?;
  let onSelect: (AccessibilityElement) -> Void;
  let onHover: ((AccessibilityElement?) -> Void)?;

  @State private var expandedItems: Set<String> = [];

  var body: some View {
    if let root = rootElement {
      ScrollViewReader { proxy in
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
            expandedItems: $expandedItems,
            onHover: onHover
          );
        }
      }
      .background(ListFocuser())
      .onAppear {
        expandToSelected(in: root);
      }
      .onChange(of: selectedElement?.id) { _, newID in
        expandToSelected(in: root);
        if let newID {
          proxy.scrollTo(newID, anchor: UnitPoint(x: 0, y: 0.5));
        }
      };
      }
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
        return ancestors.union([node.id]);
      }
    }
    return nil;
  }

  private func findElement(id: String?, in element: AccessibilityElement) -> AccessibilityElement? {
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

private struct ListFocuser: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView();
    DispatchQueue.main.async {
      guard let contentView = view.window?.contentView else { return; }
      if let outlineView = Self.findView(ofType: NSOutlineView.self, in: contentView) {
        view.window?.makeFirstResponder(outlineView);
      }
    };
    return view;
  }

  func updateNSView(_ nsView: NSView, context: Context) {}

  private static func findView<T: NSView>(ofType type: T.Type, in view: NSView) -> T? {
    if let found = view as? T { return found; }
    for subview in view.subviews {
      if let found = findView(ofType: type, in: subview) { return found; }
    }
    return nil;
  }
}

private struct TreeNodeContent: View {
  let element: AccessibilityElement;
  @Binding var expandedItems: Set<String>;
  let onHover: ((AccessibilityElement?) -> Void)?;

  var body: some View {
    if element.children.isEmpty {
      ElementTreeNodeView(element: element)
        .tag(element.id)
        .onHover { isHovered in
          onHover?(isHovered ? element : nil);
        };
    } else {
      DisclosureGroup(
        isExpanded: Binding(
          get: { expandedItems.contains(element.id) },
          set: { isExpanded in
            if isExpanded {
              expandedItems.insert(element.id);
            } else {
              expandedItems.remove(element.id);
            }
          }
        )
      ) {
        ForEach(element.children) { child in
          TreeNodeContent(
            element: child,
            expandedItems: $expandedItems,
            onHover: onHover
          );
        }
      } label: {
        ElementTreeNodeView(element: element)
          .tag(element.id)
          .onHover { isHovered in
            onHover?(isHovered ? element : nil);
          };
      }
    }
  }
}
