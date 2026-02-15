import SwiftUI

struct ContentView: View {
  @State private var isAccessibilityGranted: Bool = false;
  @State private var viewModel = InspectorViewModel();
  @State private var detailWidth: CGFloat = 350;
  @State private var dragStartWidth: CGFloat?;

  var body: some View {
    Group {
      if isAccessibilityGranted {
        mainInspectorView;
      } else {
        PermissionPromptView(
          onRequest: { AccessibilityService.requestPermission(); },
          onRecheck: { checkPermission(); }
        );
      }
    }
    .onAppear {
      checkPermission();
    };
  }

  private var mainInspectorView: some View {
    VStack(spacing: 0) {
      headerBar;
      Divider();

      GeometryReader { geometry in
        HStack(spacing: 0) {
          listArea
            .frame(maxWidth: .infinity, maxHeight: .infinity);

          splitDivider(totalWidth: geometry.size.width);

          detailPanel
            .frame(minWidth: detailWidth, maxWidth: detailWidth, maxHeight: .infinity);
        }
      }
    }
  }

  private func splitDivider(totalWidth: CGFloat) -> some View {
    Rectangle()
      .fill(Color(nsColor: .separatorColor))
      .frame(width: 1)
      .overlay {
        Rectangle()
          .fill(Color.clear)
          .frame(width: 8)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(coordinateSpace: .global)
              .onChanged { value in
                if dragStartWidth == nil {
                  dragStartWidth = detailWidth;
                }
                let newWidth = (dragStartWidth ?? detailWidth) - value.translation.width;
                detailWidth = max(200, min(totalWidth - 400, newWidth));
              }
              .onEnded { _ in
                dragStartWidth = nil;
              }
          )
          .onHover { isHovering in
            if isHovering {
              NSCursor.resizeLeftRight.push();
            } else {
              NSCursor.pop();
            }
          };
      };
  }

  private var headerBar: some View {
    HStack {
      AppSelectorView(
        apps: viewModel.runningApps,
        selectedApp: $viewModel.selectedApp,
        onOpen: { viewModel.loadRunningApps(); }
      )
      .onChange(of: viewModel.selectedApp) { oldValue, newValue in
        if let app = newValue, app.id != oldValue?.id {
          viewModel.stopPickMode();
          viewModel.stopRegionSelection();
          viewModel.clearRegionFilter();
          viewModel.selectApp(app);
        }
      };

      Picker("表示", selection: $viewModel.viewMode) {
        ForEach(InspectorViewModel.ViewMode.allCases, id: \.self) { mode in
          Text(mode.rawValue).tag(mode);
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .fixedSize();

      Button(action: { viewModel.refreshElementTree(); }) {
        Image(systemName: "arrow.clockwise");
      }
      .keyboardShortcut("r", modifiers: .command);

      Button(action: {
        if viewModel.isPickMode {
          viewModel.stopPickMode();
        } else {
          viewModel.startPickMode();
        }
      }) {
        Image(systemName: viewModel.isPickMode ? "scope" : "target");
      }
      .keyboardShortcut("p", modifiers: .command)
      .disabled(viewModel.selectedApp == nil);

      Button(action: {
        if viewModel.isRegionSelectMode {
          viewModel.stopRegionSelection();
        } else {
          viewModel.startRegionSelection();
        }
      }) {
        Image(systemName: "rectangle.dashed")
          .foregroundStyle(viewModel.isRegionSelectMode ? Color.accentColor : .primary);
      }
      .keyboardShortcut("d", modifiers: .command)
      .disabled(viewModel.selectedApp == nil || viewModel.viewMode == .tree);

      Spacer();

      Picker("属性名形式", selection: $viewModel.attributeNameStyle) {
        ForEach(AttributeNameStyle.allCases, id: \.self) { style in
          Text(style.rawValue).tag(style);
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .fixedSize();
    }
    .padding(.horizontal)
    .padding(.vertical, 8);
  }

  @ViewBuilder
  private var listArea: some View {
    VStack(spacing: 0) {
      if viewModel.viewMode == .table {
        ElementFilterView(filter: $viewModel.filter, visibleColumns: $viewModel.visibleColumns, attributeNameStyle: viewModel.attributeNameStyle, onClearRegion: { viewModel.clearRegionFilter(); })
          .padding(.horizontal)
          .padding(.vertical, 8);

        Divider();
      }

      Group {
        if viewModel.isLoading {
          ProgressView("読み込み中...");
        } else if let error = viewModel.errorMessage {
          ContentUnavailableView(
            "エラー",
            systemImage: "exclamationmark.triangle",
            description: Text(error)
          );
        } else {
          switch viewModel.viewMode {
          case .table:
            ElementListView(
              elements: viewModel.filteredElements,
              selectedElement: viewModel.selectedElement,
              onSelect: { if !viewModel.isPickMode { viewModel.selectElement($0); } },
              onHover: { if !viewModel.isPickMode { viewModel.highlightElement($0); } },
              attributeNameStyle: viewModel.attributeNameStyle,
              visibleColumns: viewModel.visibleColumns
            );
          case .tree:
            ElementTreeView(
              rootElement: viewModel.rootElement,
              selectedElement: viewModel.selectedElement,
              onSelect: { if !viewModel.isPickMode { viewModel.selectElement($0); } },
              onHover: { if !viewModel.isPickMode { viewModel.highlightElement($0); } }
            );
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity);
    }
  }

  @ViewBuilder
  private var detailPanel: some View {
    VStack(spacing: 0) {
      if viewModel.selectedApp != nil {
        HStack {
          Spacer();
          Text("要素数: \(viewModel.totalElementCount)  最大深さ: \(viewModel.maxDepth)/\(viewModel.maxDepthLimit)")
            .font(.caption)
            .foregroundStyle(.secondary);
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2);

        Divider();
      }

      if let selected = viewModel.selectedElement {
        ScrollView {
          ElementDetailView(
            element: selected,
            attributes: viewModel.selectedElementAttributes,
            attributeNameStyle: viewModel.attributeNameStyle
          );
        }
      } else {
        ContentUnavailableView(
          "要素を選択してください",
          systemImage: "sidebar.right",
          description: Text("テーブル/ツリーから要素を選択すると詳細が表示されます")
        );
      }
    }
    .frame(maxHeight: .infinity);
  }

  private func checkPermission() {
    isAccessibilityGranted = AccessibilityService.isTrusted();
  }
}
