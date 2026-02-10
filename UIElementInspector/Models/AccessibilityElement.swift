@preconcurrency import ApplicationServices
import Foundation

struct AccessibilityElement: Identifiable, Hashable {
  let id: UUID = UUID();
  nonisolated(unsafe) let axElement: AXUIElement;
  let role: String;
  let title: String?;
  let value: String?;
  let roleDescription: String?;
  let position: CGPoint?;
  let size: CGSize?;
  let depth: Int;
  let indexPath: [Int];
  var children: [AccessibilityElement];

  var stableID: String {
    "\(role)_\(indexPath.map(String.init).joined(separator: "_"))";
  }

  var flattened: [AccessibilityElement] {
    [self] + children.flatMap { $0.flattened };
  }

  var optionalChildren: [AccessibilityElement]? {
    children.isEmpty ? nil : children;
  }

  var displayLabel: String {
    let base = role.replacingOccurrences(of: "AX", with: "");
    if let title, !title.isEmpty {
      return "\(base): \"\(title)\"";
    }
    return base;
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.stableID == rhs.stableID;
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(stableID);
  }
}
