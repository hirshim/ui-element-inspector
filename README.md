# UI Element Inspector

macOS用のアクセシビリティ開発者ツール。実行中のアプリケーションのUI要素階層を検査し、詳細情報を表示します。

## 機能

- 実行中のアプリケーション一覧表示
- UI要素階層の表示（リスト/ツリー表示）
- 要素の詳細情報表示（role, title, value, position, size, 全属性）
- テキスト検索とフィルタリング（role/title/value）
- マウスホバーでUI要素をハイライト

## 動作環境

- macOS 15.0以降
- Xcode 16.0以降
- Swift 6.0

## セットアップ

```bash
# xcodegen をインストール（未インストールの場合）
brew install xcodegen

# Xcodeプロジェクトを生成
xcodegen generate

# Xcodeで開く
open UIElementInspector.xcodeproj
```

Cmd+R でビルド＆実行し、権限要求画面で「権限を要求」をクリック。
システム設定 > プライバシーとセキュリティ > アクセシビリティ で `UIElementInspector.dev` にチェックを入れ、アプリに戻って「再確認」をクリック。

## 使い方

1. 上部のドロップダウンから検査したいアプリケーションを選択
2. リスト表示またはツリー表示でUI要素を閲覧
3. テキスト検索・フィルタ（Role / Title / Value）で絞り込み
4. 要素にマウスをホバーすると、対象アプリ上でハイライト表示
5. 要素を選択すると、右ペインに全属性の詳細を表示

## 開発

### バンドルID

- Debug: `com.example.UIElementInspector.dev`
- Release: `com.example.UIElementInspector`

### アーキテクチャ

| レイヤー | 主要ファイル |
|---|---|
| Models | `AccessibilityElement`, `AppInfo`, `ElementFilter` |
| Services | `AccessibilityService`, `ApplicationService`, `HighlightOverlayService` |
| ViewModels | `InspectorViewModel` |
| Views | `ContentView`, `ElementListView`, `ElementTreeView`, `ElementDetailView` |
| Utilities | `AXUIElement+Extensions` |

### アクセシビリティ権限について

- 開発の最初にビルド＆実行して権限を付与する
- 権限付与後は変更を最小限にとどめる（不要なオン・オフの繰り返しをしない）
- `tccutil reset` や `sqlite3` によるTCCデータベース操作はシステム破損のリスクがあるため禁止
- 権限トラブル時はアプリ再起動 → Mac再起動の順で対処する

### トラブルシューティング

```bash
# アプリの再起動
killall UIElementInspector
# Xcode で Cmd+R

# クリーンビルド
xcodebuild -project UIElementInspector.xcodeproj -scheme UIElementInspector clean build
```
