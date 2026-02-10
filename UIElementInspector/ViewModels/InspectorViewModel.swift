@preconcurrency import ApplicationServices
import SwiftUI

@MainActor
@Observable
final class InspectorViewModel {
  var runningApps: [AppInfo] = [];
  var selectedApp: AppInfo?;
  var rootElement: AccessibilityElement?;
  var selectedElement: AccessibilityElement?;
  var selectedElementAttributes: [AccessibilityService.AttributeItem] = [];
  var filter: ElementFilter = ElementFilter();
  var isLoading: Bool = false;
  var errorMessage: String?;
  var viewMode: ViewMode = .list;

  enum ViewMode: String, CaseIterable {
    case list = "リスト";
    case tree = "ツリー";
  }

  private var cachedFlatElements: [AccessibilityElement] = [];
  private let accessibilityService = AccessibilityService();
  private let applicationService = ApplicationService();
  private let highlightService = HighlightOverlayService();

  var filteredElements: [AccessibilityElement] {
    cachedFlatElements.filter { element in
      filter.matches(element) && filter.matchesRegion(element);
    };
  }

  func loadRunningApps() {
    runningApps = applicationService.runningApplications();
  }

  func selectApp(_ app: AppInfo) {
    selectedApp = app;
    selectedElement = nil;
    errorMessage = nil;
    refreshElementTree();
  }

  func refreshElementTree() {
    guard let app = selectedApp else { return; }
    isLoading = true;
    errorMessage = nil;

    let pid = app.id;
    Task.detached {
      let service = AccessibilityService();
      let root = service.fetchElementTree(for: pid);
      await MainActor.run {
        self.rootElement = root;
        self.cachedFlatElements = root?.flattened ?? [];
        self.isLoading = false;
        if root == nil {
          self.errorMessage = "要素を取得できませんでした。アプリがアクセシビリティに対応していない可能性があります。";
        }
      };
    };
  }

  func selectElement(_ element: AccessibilityElement) {
    selectedElement = element;
    selectedElementAttributes = accessibilityService.allAttributes(of: element.axElement);
    highlightElement(element);
  }

  func highlightElement(_ element: AccessibilityElement?) {
    guard let element,
          let pos = element.position,
          let size = element.size else {
      highlightService.hide();
      return;
    }
    highlightService.highlight(rect: CGRect(origin: pos, size: size));
  }

  func clearHighlight() {
    highlightService.hide();
  }
}
