import SwiftUI

struct ContentView: View {
  @State private var isAccessibilityGranted: Bool = false;
  @State private var viewModel = InspectorViewModel();

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
    NavigationSplitView {
      sidebarContent
        .navigationSplitViewColumnWidth(min: 300, ideal: 400);
    } detail: {
      if let selected = viewModel.selectedElement {
        ElementDetailView(
          element: selected,
          attributes: viewModel.selectedElementAttributes
        );
      } else {
        ContentUnavailableView(
          "要素を選択してください",
          systemImage: "sidebar.left",
          description: Text("左のリストから要素を選択すると詳細が表示されます")
        );
      }
    }
    .toolbar {
      toolbarContent;
    };
  }

  @ViewBuilder
  private var sidebarContent: some View {
    VStack(spacing: 0) {
      HStack {
        Text("App:");

        AppSelectorView(
          apps: viewModel.runningApps,
          selectedApp: $viewModel.selectedApp,
          onOpen: { viewModel.loadRunningApps(); }
        )
        .onChange(of: viewModel.selectedApp) { oldValue, newValue in
          if newValue?.id != oldValue?.id, newValue != nil {
            viewModel.selectedElement = nil;
            viewModel.errorMessage = nil;
            viewModel.refreshElementTree();
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
      }
      .padding();

      Divider();

      if viewModel.viewMode == .list {
        ElementFilterView(filter: $viewModel.filter)
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
          case .list:
            ElementListView(
              elements: viewModel.filteredElements,
              selectedElement: viewModel.selectedElement,
              onSelect: { viewModel.selectElement($0); },
              onHover: { viewModel.highlightElement($0); }
            );
          case .tree:
            ElementTreeView(
              rootElement: viewModel.rootElement,
              selectedElement: viewModel.selectedElement,
              onSelect: { viewModel.selectElement($0); },
              onHover: { viewModel.highlightElement($0); }
            );
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity);
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: { viewModel.refreshElementTree(); }) {
        Label("更新", systemImage: "arrow.clockwise");
      }
      .keyboardShortcut("r", modifiers: .command);
    }
  }

  private func checkPermission() {
    isAccessibilityGranted = AccessibilityService.isTrusted();
  }
}
