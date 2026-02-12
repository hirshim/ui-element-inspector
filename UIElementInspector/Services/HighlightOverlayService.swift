import AppKit

@MainActor
final class HighlightOverlayService {
  private var overlayWindow: NSWindow?;
  private var currentRect: CGRect?;

  func highlight(rect: CGRect) {
    // 同じrectの場合は更新をスキップ
    if let current = currentRect, current == rect {
      return;
    }

    if overlayWindow == nil {
      createOverlayWindow();
    }
    let screenRect = convertToScreenCoordinates(rect);
    overlayWindow?.setFrame(screenRect, display: true);
    overlayWindow?.orderFront(nil);
    currentRect = rect;
  }

  func hide() {
    overlayWindow?.orderOut(nil);
    currentRect = nil;
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
    // AX座標系: 左上原点、Y軸は下向き
    // Screen座標系: 左下原点、Y軸は上向き

    // メインスクリーンの全体の高さを使って変換
    guard let mainScreen = NSScreen.main else { return axRect; }

    // すべてのスクリーンを考慮した全体の高さ
    let allScreensHeight = NSScreen.screens.map { $0.frame.maxY }.max() ?? mainScreen.frame.height;

    // Y座標を反転
    let flippedY = allScreensHeight - axRect.origin.y - axRect.height;

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
