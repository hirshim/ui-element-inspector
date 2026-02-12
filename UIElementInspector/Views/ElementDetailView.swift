import SwiftUI

struct ElementDetailView: View {
  let element: AccessibilityElement;
  let attributes: [AccessibilityService.AttributeItem];
  let attributeNameStyle: AttributeNameStyle;

  private static let knownSDKNames: Set<String> = Set(
    AttributeDefinition.allCases.map { $0.sdkName }
  );

  private func makeItems(for category: AttributeCategory) -> [AccessibilityService.AttributeItem] {
    let defs = AttributeDefinition.allCases.filter { $0.category == category };
    return defs.compactMap { def in
      guard let item = attributes.first(where: { $0.key == def.sdkName }) else { return nil; }
      return AccessibilityService.AttributeItem(
        key: def.displayName(style: attributeNameStyle),
        value: item.value
      );
    };
  }

  private var otherItems: [AccessibilityService.AttributeItem] {
    let items = attributes.filter { !Self.knownSDKNames.contains($0.key) };
    if attributeNameStyle == .inspector {
      return items.map { item in
        let displayKey = String(item.key.hasPrefix("AX") ? item.key.dropFirst(2) : item.key[...]);
        return AccessibilityService.AttributeItem(key: displayKey, value: item.value);
      };
    }
    return items;
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      let informational = makeItems(for: .informational);
      let visualState = makeItems(for: .visualState);
      let valueItems = makeItems(for: .value);
      let other = otherItems;

      if !informational.isEmpty {
        attributeSection(
          title: AttributeCategory.informational.rawValue,
          items: informational
        );
      }
      if !visualState.isEmpty {
        attributeSection(
          title: AttributeCategory.visualState.rawValue,
          items: visualState
        );
      }
      if !valueItems.isEmpty {
        attributeSection(
          title: AttributeCategory.value.rawValue,
          items: valueItems
        );
      }
      if !other.isEmpty {
        attributeSection(
          title: "\(AttributeCategory.other.rawValue) (\(other.count))",
          items: other
        );
      }
    }
    .padding()
    .textSelection(.enabled)
    .navigationTitle(element.displayLabel);
  }

  @ViewBuilder
  private func attributeSection(
    title: String,
    items: [AccessibilityService.AttributeItem]
  ) -> some View {
    GroupBox(title) {
      Table(items) {
        TableColumn("属性名", value: \.key)
          .width(min: 100, ideal: 200);
        TableColumn("値", value: \.value);
      }
      .frame(height: CGFloat(items.count + 1) * 26);
    }
  }
}
