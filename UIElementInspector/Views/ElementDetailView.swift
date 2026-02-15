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

  private var sections: [(title: String, items: [AccessibilityService.AttributeItem])] {
    var result: [(title: String, items: [AccessibilityService.AttributeItem])] = [
      (AttributeCategory.informational.rawValue, makeItems(for: .informational)),
      (AttributeCategory.visualState.rawValue, makeItems(for: .visualState)),
      (AttributeCategory.value.rawValue, makeItems(for: .value)),
    ].filter { !$0.items.isEmpty };
    let other = otherItems;
    if !other.isEmpty {
      result.append(("\(AttributeCategory.other.rawValue) (\(other.count))", other));
    }
    return result;
  }

  var body: some View {
    let secs = sections;
    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4) {
      ForEach(secs.indices, id: \.self) { index in
        if index > 0 {
          Divider().padding(.vertical, 4);
        }
        Text(secs[index].title)
          .font(.headline)
          .padding(.bottom, 2);
        ForEach(secs[index].items) { item in
          GridRow {
            Text(item.key)
              .foregroundStyle(.secondary);
            Text(item.value)
              .frame(maxWidth: .infinity, alignment: .leading);
          }
        }
      }
    }
    .padding()
    .textSelection(.enabled)
    .navigationTitle(element.displayLabel);
  }
}
