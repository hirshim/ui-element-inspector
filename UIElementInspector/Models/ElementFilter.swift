import Foundation

struct ElementFilter {
  var searchText: String = "";

  func matches(_ element: AccessibilityElement) -> Bool {
    guard !searchText.isEmpty else { return true; }
    let text = searchText.lowercased();

    for attr in AttributeDefinition.allCases {
      let val = element.displayValue(for: attr);
      if !val.isEmpty && val.lowercased().contains(text) { return true; }
    }

    return false;
  }
}
