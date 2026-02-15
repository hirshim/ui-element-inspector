@preconcurrency import ApplicationServices
import Foundation

struct AccessibilityElement: Identifiable, Hashable {
  nonisolated(unsafe) let axElement: AXUIElement;
  // Informational
  let role: String;
  let subrole: String?;
  let roleDescription: String?;
  let title: String?;
  let axDescription: String?;
  let help: String?;
  let identifier: String?;
  // Visual State
  let isEnabled: Bool?;
  let isFocused: Bool?;
  let position: CGPoint?;
  let size: CGSize?;
  let isSelected: Bool?;
  let isExpanded: Bool?;
  // Value
  let value: String?;
  let valueDescription: String?;
  let minValue: String?;
  let maxValue: String?;
  let placeholderValue: String?;
  // Structure
  let depth: Int;
  let indexPath: [Int];
  var children: [AccessibilityElement];

  var id: String {
    "\(role)_\(indexPath.map(String.init).joined(separator: "_"))";
  }

  var flattened: [AccessibilityElement] {
    [self] + children.flatMap { $0.flattened };
  }

  var displayLabel: String {
    let base = role.replacingOccurrences(of: "AX", with: "");
    if let title, !title.isEmpty {
      return "\(base): \"\(title)\"";
    }
    return base;
  }

  func displayValue(for attribute: AttributeDefinition) -> String {
    switch attribute {
    case .role: return role;
    case .subrole: return subrole ?? "";
    case .roleDescription: return roleDescription ?? "";
    case .title: return title ?? "";
    case .description: return axDescription ?? "";
    case .help: return help ?? "";
    case .identifier: return identifier ?? "";
    case .enabled: return isEnabled?.description ?? "";
    case .focused: return isFocused?.description ?? "";
    case .position:
      guard let pos = position else { return ""; }
      return "(\(Int(pos.x)), \(Int(pos.y)))";
    case .size:
      guard let s = size else { return ""; }
      return "\(Int(s.width)) x \(Int(s.height))";
    case .selected: return isSelected?.description ?? "";
    case .expanded: return isExpanded?.description ?? "";
    case .value: return value ?? "";
    case .valueDescription: return valueDescription ?? "";
    case .minValue: return minValue ?? "";
    case .maxValue: return maxValue ?? "";
    case .placeholderValue: return placeholderValue ?? "";
    }
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id;
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id);
  }
}
