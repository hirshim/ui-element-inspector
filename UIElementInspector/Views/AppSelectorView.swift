import SwiftUI

struct AppSelectorView: View {
  let apps: [AppInfo];
  @Binding var selectedApp: AppInfo?;
  let onOpen: () -> Void;

  var body: some View {
    Picker("アプリ", selection: $selectedApp) {
      Text("選択してください").tag(AppInfo?.none);
      ForEach(apps) { app in
        Label {
          Text(app.name);
        } icon: {
          Image(nsImage: sizedIcon(app.icon));
        }
        .tag(Optional(app));
      }
    }
    .pickerStyle(.menu)
    .labelsHidden()
    .onAppear {
      onOpen();
    };
  }

  private func sizedIcon(_ image: NSImage?) -> NSImage {
    guard let original = image else { return NSImage(); }
    let icon = original.copy() as! NSImage;
    icon.size = NSSize(width: 24, height: 24);
    return icon;
  }
}
