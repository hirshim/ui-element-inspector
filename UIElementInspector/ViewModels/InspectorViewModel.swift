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
  var viewMode: ViewMode = .table;
  var attributeNameStyle: AttributeNameStyle = .inspector;
  var visibleColumns: Set<AttributeDefinition> = Set(AttributeDefinition.allCases);

  enum ViewMode: String, CaseIterable {
    case table = "テーブル";
    case tree = "ツリー";
  }

  private var cachedFlatElements: [AccessibilityElement] = [];
  private let accessibilityService = AccessibilityService();
  private let applicationService = ApplicationService();
  private let highlightService = HighlightOverlayService();

  let maxDepthLimit: Int = 50;
  var totalElementCount: Int { cachedFlatElements.count; }
  var maxDepth: Int { cachedFlatElements.map(\.depth).max() ?? 0; }

  var filteredElements: [AccessibilityElement] {
    cachedFlatElements.filter { element in
      filter.matches(element);
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
    let service = accessibilityService;
    Task.detached {
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
    highlightElement(element);

    let axElement = element.axElement;
    let service = accessibilityService;
    Task.detached {
      let attrs = service.allAttributes(of: axElement);
      await MainActor.run {
        if self.selectedElement?.id == element.id {
          self.selectedElementAttributes = attrs;
        }
      };
    };
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

}
