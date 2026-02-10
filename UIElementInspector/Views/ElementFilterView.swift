import SwiftUI

struct ElementFilterView: View {
  @Binding var filter: ElementFilter;

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TextField("検索", text: $filter.searchText)
        .textFieldStyle(.roundedBorder);

      HStack(spacing: 12) {
        Toggle("Role", isOn: $filter.filterByRole);
        Toggle("Title", isOn: $filter.filterByTitle);
        Toggle("Value", isOn: $filter.filterByValue);
      }
      .toggleStyle(.checkbox)
      .font(.caption);
    }
  }
}
