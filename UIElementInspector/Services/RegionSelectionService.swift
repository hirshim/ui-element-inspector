import AppKit

@MainActor
final class RegionSelectionService {
  var onRegionSelected: ((_ region: CGRect) -> Void)?;
  var onCancel: (() -> Void)?;

  private var overlayWindow: KeyableWindow?;

  func start() {
    guard overlayWindow == nil else { return; }

    guard let screen = NSScreen.screens.first else { return; }
    let window = KeyableWindow(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    );
    window.isOpaque = false;
    window.backgroundColor = .clear;
    window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()));
    window.ignoresMouseEvents = false;
    window.hasShadow = false;

    let view = RegionSelectionView();
    view.screenHeight = screen.frame.height;
    view.onComplete = { [weak self] region in
      self?.onRegionSelected?(region);
      self?.stop();
    };
    view.onCancel = { [weak self] in
      self?.onCancel?();
      self?.stop();
    };
    window.contentView = view;
    window.makeKeyAndOrderFront(nil);

    self.overlayWindow = window;
  }

  func stop() {
    overlayWindow?.orderOut(nil);
    overlayWindow = nil;
    onRegionSelected = nil;
    onCancel = nil;
  }
}

// MARK: - KeyableWindow

private final class KeyableWindow: NSWindow {
  override var canBecomeKey: Bool { true; }
}

// MARK: - RegionSelectionView

private final class RegionSelectionView: NSView {
  var screenHeight: CGFloat = 0;
  var onComplete: ((_ region: CGRect) -> Void)?;
  var onCancel: (() -> Void)?;

  private var dragOrigin: CGPoint?;
  private var currentRect: CGRect?;

  override var acceptsFirstResponder: Bool { true; }

  override func draw(_ dirtyRect: NSRect) {
    // 暗いオーバーレイ
    NSColor.black.withAlphaComponent(0.1).setFill();
    bounds.fill();

    // 選択矩形
    if let rect = currentRect {
      // 塗り
      NSColor.systemBlue.withAlphaComponent(0.15).setFill();
      rect.fill();
      // 枠線
      NSColor.systemBlue.withAlphaComponent(0.8).setStroke();
      let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1));
      path.lineWidth = 2;
      path.stroke();
    }
  }

  override func mouseDown(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil);
    dragOrigin = point;
    currentRect = nil;
    NSCursor.crosshair.push();
    setNeedsDisplay(bounds);
  }

  override func mouseDragged(with event: NSEvent) {
    guard let origin = dragOrigin else { return; }
    let point = convert(event.locationInWindow, from: nil);
    let x = min(origin.x, point.x);
    let y = min(origin.y, point.y);
    let w = abs(point.x - origin.x);
    let h = abs(point.y - origin.y);
    currentRect = CGRect(x: x, y: y, width: w, height: h);
    setNeedsDisplay(bounds);
  }

  override func mouseUp(with event: NSEvent) {
    NSCursor.pop();
    guard let rect = currentRect else {
      dragOrigin = nil;
      return;
    }

    // 最小サイズ閾値（5px未満はキャンセル扱い）
    if rect.width < 5 || rect.height < 5 {
      dragOrigin = nil;
      currentRect = nil;
      onCancel?();
      return;
    }

    let axRect = screenToAXRect(rect);
    dragOrigin = nil;
    currentRect = nil;
    onComplete?(axRect);
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 { // ESC
      if dragOrigin != nil { NSCursor.pop(); }
      dragOrigin = nil;
      currentRect = nil;
      onCancel?();
    }
  }

  // Screen座標（左下原点）→ AX座標（左上原点）
  private func screenToAXRect(_ screenRect: CGRect) -> CGRect {
    let h = screenHeight;
    return CGRect(
      x: screenRect.origin.x,
      y: h - screenRect.origin.y - screenRect.height,
      width: screenRect.width,
      height: screenRect.height
    );
  }
}
