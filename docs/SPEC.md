# UI Element Inspector — 仕様・実装計画

## 製品概要

macOS向けのUI要素インスペクター。Accessibility APIを利用して、実行中のアプリケーションのUI階層をリアルタイムで解析・可視化する。

## 機能一覧と実装状況

| # | 機能 | 状態 | 関連ファイル |
|---|------|------|-------------|
| 1 | UI要素テーブル表示（18属性列） | ✅ 完了 | `ElementListView` |
| 2 | UI要素ツリー表示 | ✅ 完了 | `ElementTreeView`, `ElementTreeNodeView` |
| 3 | 要素詳細表示（4カテゴリ分類） | ✅ 完了 | `ElementDetailView` |
| 4 | テキスト検索（全18属性横断） | ✅ 完了 | `ElementFilter`, `ElementFilterView` |
| 5 | テーブル/ツリーのホバーでハイライト | ✅ 完了 | `HighlightOverlayService` |
| 6 | マウスピック（対象アプリ上で要素選択） | ✅ 完了 | `MousePickingService`, `InspectorViewModel` |
| 7 | 範囲選択フィルタ（ドラッグで矩形指定） | ✅ 完了 | `RegionSelectionService`, `ElementFilter.regionFilter` |
| 8 | 属性名トグル（SDK / Inspector形式） | ✅ 完了 | `AttributeNameStyle`, `InspectorViewModel` |

---

## 属性定義

18属性をカテゴリ分類して管理する。`AttributeDefinition` enumで一元管理。

### 情報属性 (7)

| 属性名 (Inspector) | SDK名 | 型 | 対応プロパティ |
|-------------------|-------|------|---------------|
| Role | AXRole | String | `role` |
| Subrole | AXSubrole | String? | `subrole` |
| Role Description | AXRoleDescription | String? | `roleDescription` |
| Title | AXTitle | String? | `title` |
| Description | AXDescription | String? | `axDescription` |
| Help | AXHelp | String? | `help` |
| Identifier | AXIdentifier | String? | `identifier` |

### 視覚状態 (6)

| 属性名 (Inspector) | SDK名 | 型 | 対応プロパティ |
|-------------------|-------|------|---------------|
| Enabled | AXEnabled | Bool? | `isEnabled` |
| Focused | AXFocused | Bool? | `isFocused` |
| Position | AXPosition | CGPoint? | `position` |
| Size | AXSize | CGSize? | `size` |
| Selected | AXSelected | Bool? | `isSelected` |
| Expanded | AXExpanded | Bool? | `isExpanded` |

### 値属性 (5)

| 属性名 (Inspector) | SDK名 | 型 | 対応プロパティ |
|-------------------|-------|------|---------------|
| Value | AXValue | String? | `value` |
| Value Description | AXValueDescription | String? | `valueDescription` |
| Min Value | AXMinValue | String? | `minValue` |
| Max Value | AXMaxValue | String? | `maxValue` |
| Placeholder Value | AXPlaceholderValue | String? | `placeholderValue` |

---

## 機能8: 属性名トグル

### 仕様

ツールバーの「SDK / Inspector」セグメントコントロールで属性名の表示形式を切り替える。

- **SDK形式**: `AXRole`, `AXTitle`, `AXEnabled` 等（Apple SDK定数の文字列値そのまま）
- **Inspector形式**: `Role`, `Title`, `Enabled` 等（Apple Accessibility Inspectorの慣習）

#### 適用範囲

| UI要素 | 適用 |
|--------|------|
| テーブル列ヘッダー | ✅ |
| 列フィルタのプレースホルダー | ✅ |
| 詳細ビューの属性名 | ✅ |
| ツリーノード表示 | ❌（常にInspector形式） |

#### 技術設計

- `AttributeNameStyle` enum: `.sdk` / `.inspector`
- `AttributeDefinition` enum: 18属性の定義、`displayName(style:)` で表示名を取得
- `AttributeCategory` enum: 4カテゴリ分類
- `InspectorViewModel.attributeNameStyle` で状態管理（`@Observable` で自動再描画）

---

## テーブル表示 (機能1)

### 仕様

SwiftUI `Table` を使用した18属性列＋チェックボックス列のテーブル。

#### テーブル列構成

| # | カテゴリ | 列名 | 列幅 |
|---|---------|------|------|
| 1 | — | ✓（選択） | 30 |
| 2-8 | 情報属性 | Role, Subrole, Role Description, Title, Description, Help, Identifier | 50-140 |
| 9-14 | 視覚状態 | Enabled, Focused, Position, Size, Selected, Expanded | 40-100 |
| 15-19 | 値属性 | Value, Value Description, Min Value, Max Value, Placeholder Value | 50-120 |

- 18列超のため `Group` でグルーピングして `@TableColumnBuilder` の10引数制限を回避
- クロージャパラメータには明示的な型注釈 `(element: AccessibilityElement)` が必要

#### フィルタリング

- **グローバル検索**: 全18属性を横断検索（部分一致、大文字小文字区別なし）
- **列フィルタ**: カテゴリごとに3行配置（情報7 + 視覚6 + 値5）
- `ElementFilter.columnFilters: [AttributeDefinition: String]` 辞書で管理
- グローバル検索と列フィルタはAND条件

---

## 詳細表示 (機能3)

### 仕様

要素選択時に右ペインに4セクションで属性を表示する。

| セクション | 内容 |
|-----------|------|
| 情報属性 | Role, Subrole, Role Description, Title, Description, Help, Identifier |
| 視覚状態 | Enabled, Focused, Position, Size, Selected, Expanded |
| 値属性 | Value, Value Description, Min Value, Max Value, Placeholder Value |
| その他 (n) | 上記18属性以外の全属性 |

- `allAttributes()` から取得した全属性をSDK名でカテゴリ分類
- 既知18属性は `AttributeDefinition.from(sdkName:)` でマッピング
- Inspector形式選択時は「その他」のキーも `AX` プレフィックスを除去

---

## 機能6: マウスピック（対象アプリ上で要素選択）

### 仕様

ツールバーの「ピック」ボタンを押すとピックモードに入る。対象アプリ上でマウスを動かすと、カーソル直下のUI要素をリアルタイムでハイライトし、クリックでその要素をインスペクターで選択する。

#### ユーザーフロー

1. アプリを選択し、要素ツリーが読み込まれた状態にする
2. ツールバーの「ピック」ボタン（またはキーボードショートカット）を押す
3. マウスカーソルが十字型（crosshair）に変わり、ピックモードに入る
4. 対象アプリ上でマウスを移動 → カーソル直下のUI要素がハイライトされる
5. クリック → その要素がインスペクターで選択され、詳細ペインに表示される
6. ピックモードが自動終了し、通常モードに戻る
7. Escキーでピックモードをキャンセルできる

#### 技術設計（マウスピック）

- `MousePickingService`: タイマーポーリング（50ms）でマウス位置を監視し、`AXUIElementCopyElementAtPosition`で要素を特定
- NSEvent.mouseLocation（左下原点）→ AX座標（左上原点）への変換（プライマリスクリーン基準）
- `NSEvent.addGlobalMonitorForEvents`でクリック監視、`addLocalMonitorForEvents`でESCキー監視
- PickModeとRegionSelectModeは排他制御（一方を開始すると他方を停止）

---

## 機能7: 範囲選択フィルタ（ドラッグで矩形指定）

### 仕様

テーブル表示時に「範囲選択」ボタンを押して画面上でドラッグ。矩形範囲内のUI要素だけにフィルタリングする。

#### 技術設計（範囲選択）

- `RegionSelectionService`: `KeyableWindow`（`canBecomeKey=true`のNSWindowサブクラス）でフルスクリーンオーバーレイを表示
- `RegionSelectionView`（NSView）でドラッグ矩形描画、ESCキーキャンセル、最小5px閾値
- Screen座標（左下原点）→ AX座標（左上原点）への変換後、`ElementFilter.regionFilter`にセット
- `CGRect.contains(CGRect)` で完全包含判定（要素矩形が選択矩形に完全に含まれる場合のみマッチ）
- テキスト検索とのAND条件、フィルタバーに座標表示＋✕クリアボタン
- ツリーモードでは無効（テーブル表示時のみ使用可能）

---

## 実装順序

### フェーズ1: テーブル18列化＋属性名トグル＋詳細カテゴリ分け ✅ 完了

1. ViewMode リネーム（リスト→テーブル）+ AttributeNameStyle 新規作成
2. モデル層の拡張（AXUIElement拡張、AccessibilityElement 12属性追加、buildElement更新）
3. ビュー層の全面更新（Filter辞書化、FilterView 3行、ListView 18列、DetailView 4セクション、ContentView トグル追加）

### フェーズ2: マウスピック（機能6）✅ 完了

1. `AXUIElement+Extensions` に `elementAtPosition` を追加
2. `MousePickingService` を新規作成（タイマーポーリング、グローバルクリック監視、ESCキャンセル）
3. `InspectorViewModel` にピックモード状態管理を追加
4. ツールバーにピックボタン（⌘P）を追加

### フェーズ3: 範囲選択フィルタ（機能7）✅ 完了

1. `RegionSelectionService` を新規作成（KeyableWindow + RegionSelectionView）
2. ドラッグ確定 → AX座標に変換 → `ElementFilter.regionFilter` にセット
3. `ElementFilterView` に範囲バッジ（座標表示＋✕クリア）を追加
4. ツールバーに範囲選択ボタン（⌘D）を追加

---

## 技術メモ

### SwiftUI Table の列数制限

`@TableColumnBuilder` は最大10引数。`Group` でグルーピングして回避する。Group内のクロージャには明示的な型注釈 `(element: AccessibilityElement)` が必要（コンパイラの型推論が効かないため）。

### AXUIElementCopyElementAtPosition の使い方

```swift
func elementAtPosition(_ x: Float, _ y: Float) -> AXUIElement? {
  var element: AXUIElement?;
  let result = AXUIElementCopyElementAtPosition(self, x, y, &element);
  guard result == .success else { return nil; }
  return element;
}
```

### スクリーン座標 → AX座標 変換

```swift
// ポイント変換（MousePickingService）
let screenPos = NSEvent.mouseLocation;  // 左下原点
let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0;
let axX = Float(screenPos.x);
let axY = Float(primaryScreenHeight - screenPos.y);

// 矩形変換（RegionSelectionService）
// NSView座標（左下原点）→ AX座標（左上原点）
let axRect = CGRect(x: rect.x, y: screenH - rect.y - rect.height,
                    width: rect.width, height: rect.height);
```
