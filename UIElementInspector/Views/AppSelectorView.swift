import SwiftUI

struct AppSelectorView: View {
  let apps: [AppInfo];
  @Binding var selectedApp: AppInfo?;
  let onSelect: (AppInfo) -> Void;
  let onRefreshApps: () -> Void;

  var body: some View {
    HStack {
      Picker("アプリケーション", selection: Binding(
        get: { selectedApp?.id },
        set: { id in
          if let app = apps.first(where: { $0.id == id }) {
            onSelect(app);
          }
        }
      )) {
        Text("選択してください").tag(nil as pid_t?);
        ForEach(apps) { app in
          HStack {
            if let icon = app.icon {
              Image(nsImage: icon)
                .resizable()
                .frame(width: 16, height: 16);
            }
            Text(app.name);
          }
          .tag(app.id as pid_t?);
        }
      }
      .labelsHidden();

      Button(action: onRefreshApps) {
        Image(systemName: "arrow.clockwise");
      }
      .buttonStyle(.borderless);
    }
  }
}
