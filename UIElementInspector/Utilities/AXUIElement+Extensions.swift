@preconcurrency import ApplicationServices
import CoreGraphics

extension AXUIElement {
  func getValue(_ attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?;
    guard AXUIElementCopyAttributeValue(self, attribute as CFString, &value) == .success else {
      return nil;
    }
    return value;
  }

  func typedValue<T>(_ attribute: String) -> T? {
    getValue(attribute) as? T;
  }

  var allAttributeNames: [String] {
    var names: CFArray?;
    guard AXUIElementCopyAttributeNames(self, &names) == .success else { return []; }
    return names as? [String] ?? [];
  }

  var role: String? {
    typedValue(kAXRoleAttribute);
  }

  var title: String? {
    typedValue(kAXTitleAttribute);
  }

  var children: [AXUIElement]? {
    typedValue(kAXChildrenAttribute);
  }

  var axPosition: CGPoint? {
    guard let value = getValue(kAXPositionAttribute),
          CFGetTypeID(value) == AXValueGetTypeID() else { return nil; }
    var point = CGPoint.zero;
    AXValueGetValue(value as! AXValue, .cgPoint, &point);
    return point;
  }

  var axSize: CGSize? {
    guard let value = getValue(kAXSizeAttribute),
          CFGetTypeID(value) == AXValueGetTypeID() else { return nil; }
    var size = CGSize.zero;
    AXValueGetValue(value as! AXValue, .cgSize, &size);
    return size;
  }

  var subrole: String? {
    typedValue(kAXSubroleAttribute);
  }

  var axDescription: String? {
    typedValue(kAXDescriptionAttribute);
  }

  var help: String? {
    typedValue(kAXHelpAttribute);
  }

  var identifier: String? {
    typedValue(kAXIdentifierAttribute);
  }

  var isEnabled: Bool? {
    typedValue(kAXEnabledAttribute);
  }

  var isFocused: Bool? {
    typedValue(kAXFocusedAttribute);
  }

  var isSelected: Bool? {
    typedValue(kAXSelectedAttribute);
  }

  var isExpanded: Bool? {
    typedValue(kAXExpandedAttribute);
  }

  var valueDescription: String? {
    typedValue(kAXValueDescriptionAttribute);
  }

  var minValue: String? {
    guard let v = getValue(kAXMinValueAttribute) else { return nil; }
    return String(describing: v);
  }

  var maxValue: String? {
    guard let v = getValue(kAXMaxValueAttribute) else { return nil; }
    return String(describing: v);
  }

  var placeholderValue: String? {
    typedValue(kAXPlaceholderValueAttribute);
  }

  func elementAtPosition(_ x: Float, _ y: Float) -> AXUIElement? {
    var element: AXUIElement?;
    guard AXUIElementCopyElementAtPosition(self, x, y, &element) == .success else {
      return nil;
    }
    return element;
  }
}
