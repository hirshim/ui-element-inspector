import AppKit

final class ApplicationService: Sendable {

  // MARK: - Applications

  func runningApplications() -> [AppInfo] {
    NSWorkspace.shared.runningApplications
      .filter { $0.activationPolicy == .regular }
      .map { AppInfo(from: $0) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending };
  }
}
