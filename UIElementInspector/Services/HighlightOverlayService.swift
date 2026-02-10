import AppKit

final class HighlightOverlayService {
  private var overlayWindow: NSWindow?;

  func highlight(rect: CGRect) {
    if overlayWindow == nil {
      createOverlayWindow();
    }
    let screenRect = convertToScreenCoordinates(rect);
    overlayWindow?.setFrame(screenRect, display: true);
    overlayWindow?.orderFront(nil);
  }

  func hide() {
    overlayWindow?.orderOut(nil);
  }

  private func createOverlayWindow() {
    let window = NSWindow(
      contentRect: .zero,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    );
    window.isOpaque = false;
    window.backgroundColor = .clear;
    window.level = .floating;
    window.ignoresMouseEvents = true;
    window.hasShadow = false;

    let view = HighlightView();
    window.contentView = view;

    self.overlayWindow = window;
  }

  private func convertToScreenCoordinates(_ axRect: CGRect) -> CGRect {
    guard let screen = NSScreen.main else { return axRect; }
    let screenHeight = screen.frame.height;
    let flippedY = screenHeight - axRect.origin.y - axRect.height;
    return CGRect(x: axRect.origin.x, y: flippedY, width: axRect.width, height: axRect.height);
  }
}

final class HighlightView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    NSColor.systemBlue.withAlphaComponent(0.15).setFill();
    bounds.fill();
    NSColor.systemBlue.withAlphaComponent(0.8).setStroke();
    let path = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1));
    path.lineWidth = 2;
    path.stroke();
  }
}
