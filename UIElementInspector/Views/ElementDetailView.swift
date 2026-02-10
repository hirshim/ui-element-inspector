import SwiftUI

struct ElementDetailView: View {
  let element: AccessibilityElement;
  let attributes: [AccessibilityService.AttributeItem];

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        GroupBox("基本情報") {
          VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Role", value: element.role);
            LabeledContent("Title", value: element.title ?? "(なし)");
            LabeledContent("Value", value: element.value ?? "(なし)");
            LabeledContent("Role Description", value: element.roleDescription ?? "(なし)");
            if let pos = element.position {
              LabeledContent("Position", value: "(\(Int(pos.x)), \(Int(pos.y)))");
            }
            if let size = element.size {
              LabeledContent("Size", value: "\(Int(size.width)) x \(Int(size.height))");
            }
          }
        }

        GroupBox("全属性 (\(attributes.count))") {
          Table(attributes) {
            TableColumn("属性名", value: \.key)
              .width(min: 150, ideal: 200);
            TableColumn("値", value: \.value);
          }
          .frame(minHeight: 300);
        }
      }
      .padding();
    }
    .textSelection(.enabled)
    .navigationTitle(element.displayLabel);
  }
}
