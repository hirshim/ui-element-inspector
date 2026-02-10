import AppKit

struct AppInfo: Identifiable, Hashable {
  let id: pid_t;
  let name: String;
  let bundleIdentifier: String?;
  let icon: NSImage?;

  init(from app: NSRunningApplication) {
    self.id = app.processIdentifier;
    self.name = app.localizedName ?? "Unknown";
    self.bundleIdentifier = app.bundleIdentifier;
    self.icon = app.icon;
  }
}
