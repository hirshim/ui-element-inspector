import AppKit

@Observable
final class MouseTrackingService {
  var currentMousePosition: CGPoint = .zero;
  var isTracking: Bool = false;

  private var globalMonitor: Any?;
  private var localMonitor: Any?;

  func startTracking() {
    isTracking = true;

    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
      self?.currentMousePosition = NSEvent.mouseLocation;
    };

    localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
      self?.currentMousePosition = NSEvent.mouseLocation;
      return event;
    };
  }

  func stopTracking() {
    isTracking = false;
    if let globalMonitor { NSEvent.removeMonitor(globalMonitor); }
    if let localMonitor { NSEvent.removeMonitor(localMonitor); }
    globalMonitor = nil;
    localMonitor = nil;
  }

  deinit {
    stopTracking();
  }
}
