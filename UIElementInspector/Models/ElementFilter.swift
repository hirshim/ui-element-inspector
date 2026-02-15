import Foundation

struct ElementFilter {
  var searchText: String = "";
  var regionFilter: CGRect?;

  func matches(_ element: AccessibilityElement) -> Bool {
    if !searchText.isEmpty {
      let text = searchText.lowercased();
      var textMatch = false;
      for attr in AttributeDefinition.allCases {
        let val = element.displayValue(for: attr);
        if !val.isEmpty && val.lowercased().contains(text) { textMatch = true; break; }
      }
      if !textMatch { return false; }
    }

    if let region = regionFilter {
      guard let pos = element.position, let size = element.size else { return false; }
      let elementRect = CGRect(origin: pos, size: size);
      if !region.contains(elementRect) { return false; }
    }

    return true;
  }
}
