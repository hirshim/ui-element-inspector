@preconcurrency import ApplicationServices
import Foundation

final class AccessibilityService: Sendable {

  // MARK: - Permission

  static func isTrusted() -> Bool {
    AXIsProcessTrusted();
  }

  static let trustedCheckKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String;

  static func requestPermission() {
    let options = [trustedCheckKey: true] as CFDictionary;
    _ = AXIsProcessTrustedWithOptions(options);
  }

  // MARK: - Element Tree

  func fetchElementTree(for pid: pid_t, maxDepth: Int = 50) -> AccessibilityElement? {
    let appElement = AXUIElementCreateApplication(pid);
    return buildElement(from: appElement, depth: 0, indexPath: [], maxDepth: maxDepth);
  }

  private func buildElement(
    from axElement: AXUIElement,
    depth: Int,
    indexPath: [Int],
    maxDepth: Int
  ) -> AccessibilityElement? {
    guard depth <= maxDepth else { return nil; }

    // Informational
    let role = axElement.role ?? "Unknown";
    let subrole = axElement.subrole;
    let roleDescription: String? = axElement.typedValue(kAXRoleDescriptionAttribute);
    let title = axElement.title;
    let axDescription = axElement.axDescription;
    let help = axElement.help;
    let identifier = axElement.identifier;
    // Visual State
    let isEnabled = axElement.isEnabled;
    let isFocused = axElement.isFocused;
    let position = axElement.axPosition;
    let size = axElement.axSize;
    let isSelected = axElement.isSelected;
    let isExpanded = axElement.isExpanded;
    // Value
    let value: String? = {
      guard let v = axElement.getValue(kAXValueAttribute) else { return nil; }
      return String(describing: v);
    }();
    let valueDescription = axElement.valueDescription;
    let minValue = axElement.minValue;
    let maxValue = axElement.maxValue;
    let placeholderValue = axElement.placeholderValue;

    var childElements: [AccessibilityElement] = [];
    if let axChildren = axElement.children {
      childElements = axChildren.enumerated().compactMap { index, child in
        buildElement(from: child, depth: depth + 1, indexPath: indexPath + [index], maxDepth: maxDepth);
      };
    }

    return AccessibilityElement(
      axElement: axElement,
      role: role,
      subrole: subrole,
      roleDescription: roleDescription,
      title: title,
      axDescription: axDescription,
      help: help,
      identifier: identifier,
      isEnabled: isEnabled,
      isFocused: isFocused,
      position: position,
      size: size,
      isSelected: isSelected,
      isExpanded: isExpanded,
      value: value,
      valueDescription: valueDescription,
      minValue: minValue,
      maxValue: maxValue,
      placeholderValue: placeholderValue,
      depth: depth,
      indexPath: indexPath,
      children: childElements
    );
  }

  // MARK: - Attributes

  struct AttributeItem: Identifiable {
    let id: String;
    let key: String;
    let value: String;

    init(key: String, value: String) {
      self.id = key;
      self.key = key;
      self.value = value;
    }
  }

  func allAttributes(of element: AXUIElement) -> [AttributeItem] {
    let names = element.allAttributeNames;
    return names.compactMap { name in
      guard let value = element.getValue(name) else { return nil; }
      return AttributeItem(key: name, value: describeValue(value));
    };
  }

  private func describeValue(_ value: CFTypeRef) -> String {
    let typeID = CFGetTypeID(value);
    if typeID == CFStringGetTypeID() { return value as! String; }
    if typeID == CFBooleanGetTypeID() { return (value as! Bool).description; }
    if typeID == CFNumberGetTypeID() { return (value as! NSNumber).description; }
    if typeID == AXValueGetTypeID() { return describeAXValue(value as! AXValue); }
    if typeID == CFArrayGetTypeID() { return "[\((value as! [Any]).count) items]"; }
    if typeID == AXUIElementGetTypeID() { return "<AXUIElement>"; }
    return String(describing: value);
  }

  private func describeAXValue(_ axValue: AXValue) -> String {
    switch AXValueGetType(axValue) {
    case .cgPoint:
      var point = CGPoint.zero;
      AXValueGetValue(axValue, .cgPoint, &point);
      return "(\(Int(point.x)), \(Int(point.y)))";
    case .cgSize:
      var size = CGSize.zero;
      AXValueGetValue(axValue, .cgSize, &size);
      return "\(Int(size.width)) x \(Int(size.height))";
    case .cgRect:
      var rect = CGRect.zero;
      AXValueGetValue(axValue, .cgRect, &rect);
      return "(\(Int(rect.origin.x)), \(Int(rect.origin.y)), \(Int(rect.width)), \(Int(rect.height)))";
    default:
      return "<AXValue>";
    }
  }
}
