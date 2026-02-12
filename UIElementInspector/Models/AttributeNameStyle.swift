import Foundation

enum AttributeNameStyle: String, CaseIterable {
  case sdk = "SDK";
  case inspector = "Inspector";
}

enum AttributeDefinition: CaseIterable {
  // Informational
  case role;
  case subrole;
  case roleDescription;
  case title;
  case description;
  case help;
  case identifier;
  // Visual State
  case enabled;
  case focused;
  case position;
  case size;
  case selected;
  case expanded;
  // Value
  case value;
  case valueDescription;
  case minValue;
  case maxValue;
  case placeholderValue;

  var sdkName: String {
    switch self {
    case .role: return "AXRole";
    case .subrole: return "AXSubrole";
    case .roleDescription: return "AXRoleDescription";
    case .title: return "AXTitle";
    case .description: return "AXDescription";
    case .help: return "AXHelp";
    case .identifier: return "AXIdentifier";
    case .enabled: return "AXEnabled";
    case .focused: return "AXFocused";
    case .position: return "AXPosition";
    case .size: return "AXSize";
    case .selected: return "AXSelected";
    case .expanded: return "AXExpanded";
    case .value: return "AXValue";
    case .valueDescription: return "AXValueDescription";
    case .minValue: return "AXMinValue";
    case .maxValue: return "AXMaxValue";
    case .placeholderValue: return "AXPlaceholderValue";
    }
  }

  var inspectorName: String {
    switch self {
    case .role: return "Role";
    case .subrole: return "Subrole";
    case .roleDescription: return "Role Description";
    case .title: return "Title";
    case .description: return "Description";
    case .help: return "Help";
    case .identifier: return "Identifier";
    case .enabled: return "Enabled";
    case .focused: return "Focused";
    case .position: return "Position";
    case .size: return "Size";
    case .selected: return "Selected";
    case .expanded: return "Expanded";
    case .value: return "Value";
    case .valueDescription: return "Value Description";
    case .minValue: return "Min Value";
    case .maxValue: return "Max Value";
    case .placeholderValue: return "Placeholder Value";
    }
  }

  func displayName(style: AttributeNameStyle) -> String {
    switch style {
    case .sdk: return sdkName;
    case .inspector: return inspectorName;
    }
  }

  var category: AttributeCategory {
    switch self {
    case .role, .subrole, .roleDescription, .title, .description, .help, .identifier:
      return .informational;
    case .enabled, .focused, .position, .size, .selected, .expanded:
      return .visualState;
    case .value, .valueDescription, .minValue, .maxValue, .placeholderValue:
      return .value;
    }
  }

  static func from(sdkName: String) -> AttributeDefinition? {
    allCases.first { $0.sdkName == sdkName };
  }
}

enum AttributeCategory: String, CaseIterable {
  case informational = "情報属性";
  case visualState = "視覚状態";
  case value = "値属性";
  case other = "その他";
}
