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

  var isPickMode: Bool = false;
  var isRegionSelectMode: Bool = false;

  private var cachedFlatElements: [AccessibilityElement] = [];
  private let accessibilityService = AccessibilityService();
  private let applicationService = ApplicationService();
  private let highlightService = HighlightOverlayService();
  private let mousePickingService = MousePickingService();
  private let regionSelectionService = RegionSelectionService();
  private let axObserverService = AXObserverService();
  private var terminationObserver: Any?;

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
    observeAppTermination(pid: app.id);
    startObserving(pid: app.id);
    refreshElementTree();
  }

  func refreshElementTree(completion: (@MainActor @Sendable () -> Void)? = nil) {
    guard let app = selectedApp else { return; }

    let pid = app.id;
    guard NSRunningApplication(processIdentifier: pid) != nil else {
      handleAppTerminated();
      return;
    }

    isLoading = true;
    errorMessage = nil;
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
        completion?();
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

  // MARK: - Pick Mode

  func startPickMode() {
    guard let app = selectedApp, !isPickMode else { return; }
    stopRegionSelection();
    isPickMode = true;

    mousePickingService.onHover = { [weak self] axElement, position, size in
      guard let self, self.isPickMode else { return; }
      if let position, let size {
        self.highlightService.highlight(rect: CGRect(origin: position, size: size));
      }
      if let matched = self.findElementInTree(axElement: axElement) {
        if self.selectedElement?.id != matched.id {
          self.selectedElement = matched;
        }
      }
    };

    mousePickingService.onPick = { [weak self] axElement in
      guard let self, self.isPickMode else { return; }
      self.stopPickMode();
      if let matched = self.findElementInTree(axElement: axElement) {
        self.selectElement(matched);
      } else {
        self.refreshAndSelect(axElement: axElement);
      }
    };

    mousePickingService.onCancel = { [weak self] in
      self?.stopPickMode();
    };

    mousePickingService.start(for: app.id);
  }

  func stopPickMode() {
    guard isPickMode else { return; }
    isPickMode = false;
    mousePickingService.stop();
    highlightService.hide();
  }

  // MARK: - Region Selection

  func startRegionSelection() {
    guard selectedApp != nil, !isRegionSelectMode else { return; }
    stopPickMode();
    isRegionSelectMode = true;

    regionSelectionService.onRegionSelected = { [weak self] region in
      guard let self else { return; }
      self.filter.regionFilter = region;
      self.isRegionSelectMode = false;
    };

    regionSelectionService.onCancel = { [weak self] in
      self?.isRegionSelectMode = false;
    };

    regionSelectionService.start();
  }

  func stopRegionSelection() {
    guard isRegionSelectMode else { return; }
    isRegionSelectMode = false;
    regionSelectionService.stop();
  }

  func clearRegionFilter() {
    filter.regionFilter = nil;
  }

  // MARK: - App Lifecycle

  private func observeAppTermination(pid: pid_t) {
    if let old = terminationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(old);
    }
    terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didTerminateApplicationNotification,
      object: nil, queue: .main
    ) { [weak self] notification in
      let terminatedPID = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier;
      MainActor.assumeIsolated {
        guard let self, terminatedPID == pid else { return; }
        self.handleAppTerminated();
      };
    };
  }

  private func startObserving(pid: pid_t) {
    axObserverService.onElementsChanged = { [weak self] in
      self?.refreshElementTree();
    };
    axObserverService.start(for: pid);
  }

  private func handleAppTerminated() {
    stopPickMode();
    stopRegionSelection();
    axObserverService.stop();
    rootElement = nil;
    cachedFlatElements = [];
    selectedElement = nil;
    selectedElementAttributes = [];
    errorMessage = "対象アプリケーションが終了しました。";
  }

  // MARK: - Helpers

  private func findElementInTree(axElement: AXUIElement) -> AccessibilityElement? {
    cachedFlatElements.first { CFEqual($0.axElement, axElement) };
  }

  private func refreshAndSelect(axElement: AXUIElement) {
    refreshElementTree { [weak self] in
      guard let self,
            let matched = self.findElementInTree(axElement: axElement) else { return; }
      self.selectElement(matched);
    };
  }

}
