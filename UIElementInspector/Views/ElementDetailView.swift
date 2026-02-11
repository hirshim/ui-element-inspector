import SwiftUI

struct ElementDetailView: View {
  let element: AccessibilityElement;
  let attributes: [AccessibilityService.AttributeItem];

  @State private var columnCustomization = TableColumnCustomization<AccessibilityService.AttributeItem>();

  private var basicInfo: [AccessibilityService.AttributeItem] {
    var items: [AccessibilityService.AttributeItem] = [
      .init(key: "Role", value: element.role),
      .init(key: "Title", value: element.title ?? "(なし)"),
      .init(key: "Value", value: element.value ?? "(なし)"),
      .init(key: "Role Description", value: element.roleDescription ?? "(なし)"),
    ];
    if let pos = element.position {
      items.append(.init(key: "Position", value: "(\(Int(pos.x)), \(Int(pos.y)))"));
    }
    if let size = element.size {
      items.append(.init(key: "Size", value: "\(Int(size.width)) x \(Int(size.height))"));
    }
    return items;
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      GroupBox("基本情報") {
        Table(basicInfo, columnCustomization: $columnCustomization) {
          TableColumn("属性名", value: \.key)
            .width(min: 100, ideal: 200)
            .customizationID("key");
          TableColumn("値", value: \.value)
            .customizationID("value");
        }
        .frame(height: CGFloat(basicInfo.count + 1) * 26);
      }

      GroupBox("全属性 (\(attributes.count))") {
        Table(attributes, columnCustomization: $columnCustomization) {
          TableColumn("属性名", value: \.key)
            .width(min: 100, ideal: 200)
            .customizationID("key");
          TableColumn("値", value: \.value)
            .customizationID("value");
        }
      }
      .frame(maxHeight: .infinity);
    }
    .padding()
    .textSelection(.enabled)
    .navigationTitle(element.displayLabel);
  }
}
