@preconcurrency import ApplicationServices
import Foundation

@MainActor
final class AXObserverService {
  var onElementsChanged: (() -> Void)?;

  private var observer: AXObserver?;
  private var targetPID: pid_t = 0;
  private var debounceTask: Task<Void, Never>?;

  private let notifications: [String] = [
    kAXCreatedNotification,
    kAXUIElementDestroyedNotification,
    kAXMovedNotification,
    kAXResizedNotification,
    kAXTitleChangedNotification,
    kAXValueChangedNotification,
    kAXFocusedUIElementChangedNotification,
  ];

  func start(for pid: pid_t) {
    stop();
    targetPID = pid;

    let callbackPointer = Unmanaged.passUnretained(self).toOpaque();
    var obs: AXObserver?;
    guard AXObserverCreate(pid, axObserverCallback, &obs) == .success,
          let observer = obs else { return; }

    self.observer = observer;
    let appElement = AXUIElementCreateApplication(pid);

    for notification in notifications {
      AXObserverAddNotification(observer, appElement, notification as CFString, callbackPointer);
    }

    CFRunLoopAddSource(
      CFRunLoopGetMain(),
      AXObserverGetRunLoopSource(observer),
      .defaultMode
    );
  }

  func stop() {
    debounceTask?.cancel();
    debounceTask = nil;
    if let observer {
      CFRunLoopRemoveSource(
        CFRunLoopGetMain(),
        AXObserverGetRunLoopSource(observer),
        .defaultMode
      );
    }
    observer = nil;
    targetPID = 0;
  }

  fileprivate func scheduleRefresh() {
    debounceTask?.cancel();
    debounceTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(300));
      guard !Task.isCancelled else { return; }
      self.onElementsChanged?();
    };
  }
}

private func axObserverCallback(
  _ observer: AXObserver,
  _ element: AXUIElement,
  _ notification: CFString,
  _ refcon: UnsafeMutableRawPointer?
) {
  guard let refcon else { return; }
  let service = Unmanaged<AXObserverService>.fromOpaque(refcon).takeUnretainedValue();
  MainActor.assumeIsolated {
    service.scheduleRefresh();
  };
}
