import SwiftUI

struct ElementListView: View {
  let elements: [AccessibilityElement];
  let selectedElement: AccessibilityElement?;
  let onSelect: (AccessibilityElement) -> Void;
  let onHover: ((AccessibilityElement?) -> Void)?;
  let attributeNameStyle: AttributeNameStyle;
  let visibleColumns: Set<AttributeDefinition>;

  @State private var selectedID: String?;
  @State private var columnCustomization = TableColumnCustomization<AccessibilityElement>();

  private func header(_ attr: AttributeDefinition) -> String {
    attr.displayName(style: attributeNameStyle);
  }

  var body: some View {
    ScrollViewReader { proxy in
    Table(of: AccessibilityElement.self, selection: $selectedID, columnCustomization: $columnCustomization) {
      Group {
        TableColumn(header(.role)) { (element: AccessibilityElement) in
          Text(element.role)
            .font(.system(.body, design: .monospaced));
        }
        .width(min: 80, ideal: 140)
        .customizationID(AttributeDefinition.role.sdkName);

        TableColumn(header(.subrole)) { (element: AccessibilityElement) in
          Text(element.subrole ?? "(なし)")
            .foregroundStyle(element.subrole != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.subrole.sdkName);

        TableColumn(header(.roleDescription)) { (element: AccessibilityElement) in
          Text(element.roleDescription ?? "(なし)")
            .foregroundStyle(element.roleDescription != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.roleDescription.sdkName);

        TableColumn(header(.title)) { (element: AccessibilityElement) in
          Text(element.title ?? "(なし)")
            .foregroundStyle(element.title != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 120)
        .customizationID(AttributeDefinition.title.sdkName);

        TableColumn(header(.description)) { (element: AccessibilityElement) in
          Text(element.axDescription ?? "(なし)")
            .foregroundStyle(element.axDescription != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.description.sdkName);

        TableColumn(header(.help)) { (element: AccessibilityElement) in
          Text(element.help ?? "(なし)")
            .foregroundStyle(element.help != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.help.sdkName);

        TableColumn(header(.identifier)) { (element: AccessibilityElement) in
          Text(element.identifier ?? "(なし)")
            .foregroundStyle(element.identifier != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.identifier.sdkName);
      }

      Group {
        TableColumn(header(.enabled)) { (element: AccessibilityElement) in
          Text(element.isEnabled?.description ?? "(なし)")
            .foregroundStyle(element.isEnabled != nil ? .primary : .secondary);
        }
        .width(min: 40, ideal: 60)
        .customizationID(AttributeDefinition.enabled.sdkName);

        TableColumn(header(.focused)) { (element: AccessibilityElement) in
          Text(element.isFocused?.description ?? "(なし)")
            .foregroundStyle(element.isFocused != nil ? .primary : .secondary);
        }
        .width(min: 40, ideal: 60)
        .customizationID(AttributeDefinition.focused.sdkName);

        TableColumn(header(.position)) { (element: AccessibilityElement) in
          if let pos = element.position {
            Text("(\(Int(pos.x)), \(Int(pos.y)))");
          } else {
            Text("(なし)")
              .foregroundStyle(.secondary);
          }
        }
        .width(min: 60, ideal: 100)
        .customizationID(AttributeDefinition.position.sdkName);

        TableColumn(header(.size)) { (element: AccessibilityElement) in
          if let size = element.size {
            Text("\(Int(size.width)) x \(Int(size.height))");
          } else {
            Text("(なし)")
              .foregroundStyle(.secondary);
          }
        }
        .width(min: 60, ideal: 100)
        .customizationID(AttributeDefinition.size.sdkName);

        TableColumn(header(.selected)) { (element: AccessibilityElement) in
          Text(element.isSelected?.description ?? "(なし)")
            .foregroundStyle(element.isSelected != nil ? .primary : .secondary);
        }
        .width(min: 40, ideal: 60)
        .customizationID(AttributeDefinition.selected.sdkName);

        TableColumn(header(.expanded)) { (element: AccessibilityElement) in
          Text(element.isExpanded?.description ?? "(なし)")
            .foregroundStyle(element.isExpanded != nil ? .primary : .secondary);
        }
        .width(min: 40, ideal: 60)
        .customizationID(AttributeDefinition.expanded.sdkName);
      }

      Group {
        TableColumn(header(.value)) { (element: AccessibilityElement) in
          Text(element.value ?? "(なし)")
            .foregroundStyle(element.value != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 120)
        .customizationID(AttributeDefinition.value.sdkName);

        TableColumn(header(.valueDescription)) { (element: AccessibilityElement) in
          Text(element.valueDescription ?? "(なし)")
            .foregroundStyle(element.valueDescription != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.valueDescription.sdkName);

        TableColumn(header(.minValue)) { (element: AccessibilityElement) in
          Text(element.minValue ?? "(なし)")
            .foregroundStyle(element.minValue != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 80)
        .customizationID(AttributeDefinition.minValue.sdkName);

        TableColumn(header(.maxValue)) { (element: AccessibilityElement) in
          Text(element.maxValue ?? "(なし)")
            .foregroundStyle(element.maxValue != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 80)
        .customizationID(AttributeDefinition.maxValue.sdkName);

        TableColumn(header(.placeholderValue)) { (element: AccessibilityElement) in
          Text(element.placeholderValue ?? "(なし)")
            .foregroundStyle(element.placeholderValue != nil ? .primary : .secondary);
        }
        .width(min: 50, ideal: 100)
        .customizationID(AttributeDefinition.placeholderValue.sdkName);
      }
    } rows: {
      ForEach(elements) { element in
        TableRow(element)
          .onHover { isHovered in
            onHover?(isHovered ? element : nil);
          };
      }
    }
    .onAppear { syncColumnVisibility(); }
    .onChange(of: visibleColumns) { _, _ in syncColumnVisibility(); }
    .onChange(of: selectedID) { _, newID in
      if let newID, let el = elements.first(where: { $0.id == newID }) {
        onSelect(el);
      }
    }
    .onChange(of: selectedElement?.id) { _, newID in
      if selectedID != newID {
        selectedID = newID;
        if let newID {
          proxy.scrollTo(newID, anchor: UnitPoint(x: 0, y: 0.5));
        }
      }
    };
    }
  }

  private func syncColumnVisibility() {
    for attr in AttributeDefinition.allCases {
      columnCustomization[visibility: attr.sdkName] = visibleColumns.contains(attr) ? .visible : .hidden;
    }
  }
}
