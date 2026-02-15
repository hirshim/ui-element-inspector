@preconcurrency import ApplicationServices
import AppKit

@MainActor
final class MousePickingService {
  private(set) var isActive: Bool = false;

  var onHover: ((_ element: AXUIElement, _ position: CGPoint?, _ size: CGSize?) -> Void)?;
  var onPick: ((_ element: AXUIElement) -> Void)?;
  var onCancel: (() -> Void)?;

  private var pollingTimer: Timer?;
  private var globalClickMonitor: Any?;
  private var localKeyMonitor: Any?;
  private var targetPID: pid_t = 0;
  private var queryInFlight: Bool = false;
  private var lastMouseLocation: CGPoint = .zero;

  func start(for pid: pid_t) {
    guard !isActive else { return; }
    isActive = true;
    targetPID = pid;

    // タイマーでマウス位置をポーリング（mouseMoved はアプリ側の設定に依存するため不使用）
    pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.pollMousePosition();
      };
    };

    globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.handleClick();
      };
    };

    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if event.keyCode == 53 {
        MainActor.assumeIsolated {
          self?.onCancel?();
        };
        return nil;
      }
      return event;
    };
  }

  func stop() {
    isActive = false;
    pollingTimer?.invalidate();
    pollingTimer = nil;
    if let globalClickMonitor { NSEvent.removeMonitor(globalClickMonitor); }
    if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor); }
    globalClickMonitor = nil;
    localKeyMonitor = nil;
    targetPID = 0;
    onHover = nil;
    onPick = nil;
    onCancel = nil;
    queryInFlight = false;
    lastMouseLocation = .zero;
  }

  private func pollMousePosition() {
    let pos = NSEvent.mouseLocation;
    guard !queryInFlight, pos != lastMouseLocation else { return; }
    lastMouseLocation = pos;
    queryInFlight = true;

    let axCoords = screenToAXCoordinates(pos);
    let pid = targetPID;

    Task.detached {
      let appElement = AXUIElementCreateApplication(pid);
      guard let found = appElement.elementAtPosition(axCoords.x, axCoords.y) else {
        await MainActor.run { self.queryInFlight = false; };
        return;
      }
      let position = found.axPosition;
      let size = found.axSize;
      await MainActor.run {
        self.queryInFlight = false;
        self.onHover?(found, position, size);
      };
    };
  }

  private func handleClick() {
    let pos = NSEvent.mouseLocation;
    let axCoords = screenToAXCoordinates(pos);
    let pid = targetPID;

    Task.detached {
      let appElement = AXUIElementCreateApplication(pid);
      guard let found = appElement.elementAtPosition(axCoords.x, axCoords.y) else { return; }
      await MainActor.run {
        self.onPick?(found);
      };
    };
  }

  private func screenToAXCoordinates(_ screenPos: CGPoint) -> (x: Float, y: Float) {
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0;
    let axX = Float(screenPos.x);
    let axY = Float(primaryScreenHeight - screenPos.y);
    return (axX, axY);
  }
}
