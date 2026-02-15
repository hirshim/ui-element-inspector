# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

macOS用アクセシビリティ検査ツール。実行中アプリのUI要素階層をリアルタイムで検査・表示する。

## ビルド・実行

```bash
# xcodegen でプロジェクト生成（project.yml → .xcodeproj）
brew install xcodegen
xcodegen generate

# ビルド
xcodebuild -project UIElementInspector.xcodeproj -scheme UIElementInspector build

# クリーンビルド
xcodebuild -project UIElementInspector.xcodeproj -scheme UIElementInspector clean build

# Xcodeで開いてCmd+Rで実行
open UIElementInspector.xcodeproj
```

テストターゲットは未設定。動作確認は手動（ビルド成功 → 起動 → 実アプリで検査）。

## 技術スタック

- Swift 6.0（strict concurrency: complete）
- macOS 15.0+ / Xcode 16.0+
- SwiftUI + AppKit（NSImage, NSWindow, NSRunningApplication）
- ApplicationServices（AXUIElement API）
- サンドボックス無効（他アプリ監視のため）

## アーキテクチャ

MVVM構成。`InspectorViewModel`が`@MainActor @Observable`で状態管理し、5つのServiceが各機能を担当。

```
App/          → @main エントリポイント
Models/       → AccessibilityElement, AppInfo, ElementFilter
Services/     → AccessibilityService, ApplicationService, HighlightOverlayService,
                MousePickingService, RegionSelectionService
ViewModels/   → InspectorViewModel（唯一のVM、全状態を集約）
Views/        → ContentView（権限ゲート + HStack分割）、各サブビュー
Utilities/    → AXUIElement+Extensions（CF APIのSwiftラッパー）
Resources/    → Info.plist, entitlements, Assets.xcassets
```

## 重要な設計判断

### アクセシビリティ権限
- アプリ起動時に`AXIsProcessTrusted()`で権限チェック → 未付与なら`PermissionPromptView`を表示
- **権限付与後は変更を最小限に**。tccutil/sqlite3によるTCCデータベース操作は禁止
- 権限トラブル時: アプリ再起動 → Mac再起動の順で対処

### Core Foundation連携
- `@preconcurrency import ApplicationServices`でStrict Concurrency対応
- `AXUIElement`は`nonisolated(unsafe)`で保持（CFTypeRefはSendable不可）
- 要素ツリー取得は`Task.detached`でバックグラウンド実行し`MainActor.run`で戻す

### 座標系変換
- AX座標: 左上原点、Y軸下向き
- スクリーン座標: 左下原点、Y軸上向き
- `HighlightOverlayService`、`MousePickingService`、`RegionSelectionService`で変換処理
- 変換式: `axY = primaryScreenHeight - screenY - height`（プライマリスクリーン基準）

### ツリービュー展開状態

- `expandedItems: Set<String>`で`id`（role + indexPath）ベースの展開管理
- UUID（リフレッシュで再生成）ではなくstable IDを使うことでツリー更新後も展開状態を維持

### マウスピック・範囲選択

- PickModeとRegionSelectModeは排他制御（一方を開始すると他方を自動停止）
- `MousePickingService`: タイマーポーリング（50ms）、`queryInFlight`フラグでAX API呼び出しを直列化
- `RegionSelectionService`: `KeyableWindow`（borderless NSWindowサブクラス、`canBecomeKey=true`）でESCキー受信
- オーバーレイウィンドウは`CGShieldingWindowLevel`で最前面表示

## コードスタイル

- インデント: スペース2つ
- セミコロン: 省略しない（全行末に付与）
- 変数名: camelCase
- コミット: Conventional Commits形式（feat/fix/docs/refactor）
- 日本語UIラベル（「基本情報」「全属性」「要素なし」等）

## project.yml（xcodegen）

`project.yml`を編集後は`xcodegen generate`で`.xcodeproj`を再生成する。pbxprojの直接編集は避ける。

- バンドルID: `com.hirshim.UIElementInspector`
- 開発チーム: `7YNKVG32P3`
- コード署名: Automatic
