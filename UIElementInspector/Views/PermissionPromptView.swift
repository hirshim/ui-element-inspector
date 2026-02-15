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

      VStack(alignment: .leading, spacing: 8) {
        Text("手順:")
          .font(.headline);
        Text("1. 「権限を要求」をクリック");
        Text("2. システム設定でUI Element Inspector（またはXcode）を探す");
        Text("3. チェックボックスをオンにする");
        Text("4. このアプリに戻って「再確認」をクリック");
        Text("5. それでも表示されない場合はアプリを再起動");
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .cornerRadius(8);

      HStack(spacing: 12) {
        Button("権限を要求") {
          onRequest();
        }
        .buttonStyle(.borderedProminent);

        Button("再確認") {
          onRecheck();
        }
        .buttonStyle(.bordered);
      }

      #if DEBUG
      Text("デバッグ: AXIsProcessTrusted = \(AccessibilityService.isTrusted())")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top);
      #endif
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(40);
  }
}
