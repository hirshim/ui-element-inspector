import SwiftUI

struct PermissionPromptView: View {
  let onRequest: () -> Void;
  let onRecheck: () -> Void;

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "lock.shield")
        .font(.system(size: 64))
        .foregroundStyle(.secondary);

      Text("アクセシビリティの権限が必要です")
        .font(.title2);

      Text("UI要素を検査するために、システム設定でアクセシビリティの許可を付与してください。")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary);

      HStack(spacing: 12) {
        Button("権限を要求") { onRequest(); }
          .buttonStyle(.borderedProminent);

        Button("再確認") { onRecheck(); }
          .buttonStyle(.bordered);
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(40);
  }
}
