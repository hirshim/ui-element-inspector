import Foundation

struct ElementFilter {
  var searchText: String = "";
  var filterByRole: Bool = true;
  var filterByTitle: Bool = true;
  var filterByValue: Bool = true;
  var regionFilter: CGRect?;

  func matches(_ element: AccessibilityElement) -> Bool {
    guard !searchText.isEmpty else { return true; }
    let text = searchText.lowercased();

    if filterByRole, element.role.lowercased().contains(text) { return true; }
    if filterByTitle, element.title?.lowercased().contains(text) == true { return true; }
    if filterByValue, element.value?.lowercased().contains(text) == true { return true; }

    return false;
  }

  func matchesRegion(_ element: AccessibilityElement) -> Bool {
    guard let region = regionFilter,
          let pos = element.position,
          let size = element.size else { return true; }
    let elementRect = CGRect(origin: pos, size: size);
    return region.intersects(elementRect);
  }
}
