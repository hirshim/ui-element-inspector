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
}
