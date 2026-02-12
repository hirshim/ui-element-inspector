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

  static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
    lhs.id == rhs.id;
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id);
  }
}
