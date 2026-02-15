import AppKit

@MainActor
final class RegionSelectionService {
  var onRegionSelected: ((_ region: CGRect) -> Void)?;
  var onCancel: (() -> Void)?;

  private var overlayWindow: KeyableWindow?;

  func start() {
    guard overlayWindow == nil else { return; }

    let screens = NSScreen.screens;
    guard !screens.isEmpty else { return; }
    let unionFrame = screens.dropFirst().reduce(screens[0].frame) { $0.union($1.frame) };
    let primaryHeight = screens[0].frame.height;

    let window = KeyableWindow(
      contentRect: unionFrame,
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
    view.screenHeight = primaryHeight;
    view.windowOrigin = unionFrame.origin;
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
  var windowOrigin: CGPoint = .zero;
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

  // ビューローカル座標 → AX座標（プライマリスクリーン左上原点）
  private func screenToAXRect(_ viewRect: CGRect) -> CGRect {
    let h = screenHeight;
    return CGRect(
      x: windowOrigin.x + viewRect.origin.x,
      y: h - (windowOrigin.y + viewRect.origin.y) - viewRect.height,
      width: viewRect.width,
      height: viewRect.height
    );
  }
}
