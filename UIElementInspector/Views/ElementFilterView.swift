import SwiftUI

struct ElementFilterView: View {
  @Binding var filter: ElementFilter;
  @Binding var visibleColumns: Set<AttributeDefinition>;
  let attributeNameStyle: AttributeNameStyle;

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      TextField("", text: $filter.searchText)
        .textFieldStyle(.roundedBorder);

      FlowLayout(spacing: 2) {
        ForEach(AttributeDefinition.allCases, id: \.self) { attr in
          columnToggle(attr);
        }
      }
    }
  }

  private func columnToggle(_ attr: AttributeDefinition) -> some View {
    let isVisible = visibleColumns.contains(attr);
    return Button {
      if isVisible {
        visibleColumns.remove(attr);
      } else {
        visibleColumns.insert(attr);
      }
    } label: {
      Text(attr.displayName(style: attributeNameStyle))
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(isVisible ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .foregroundStyle(isVisible ? .primary : .tertiary);
    }
    .buttonStyle(.plain);
  }
}

struct FlowLayout: Layout {
  let spacing: CGFloat;

  struct CacheData {
    var rows: [[Int]];
    var sizes: [CGSize];
  }

  func makeCache(subviews: Subviews) -> CacheData {
    CacheData(rows: [], sizes: []);
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
    cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) };
    cache.rows = computeRows(maxWidth: proposal.width ?? .infinity, sizes: cache.sizes);
    var height: CGFloat = 0;
    for (index, row) in cache.rows.enumerated() {
      let rowHeight = row.map { cache.sizes[$0].height }.max() ?? 0;
      height += rowHeight;
      if index > 0 { height += spacing; }
    }
    return CGSize(width: proposal.width ?? 0, height: height);
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
    var y = bounds.minY;
    for (index, row) in cache.rows.enumerated() {
      if index > 0 { y += spacing; }
      let rowHeight = row.map { cache.sizes[$0].height }.max() ?? 0;
      var x = bounds.minX;
      for i in row {
        let size = cache.sizes[i];
        subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size));
        x += size.width + spacing;
      }
      y += rowHeight;
    }
  }

  private func computeRows(maxWidth: CGFloat, sizes: [CGSize]) -> [[Int]] {
    var rows: [[Int]] = [[]];
    var currentWidth: CGFloat = 0;

    for (index, size) in sizes.enumerated() {
      if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
        rows.append([]);
        currentWidth = 0;
      }
      rows[rows.count - 1].append(index);
      currentWidth += size.width + spacing;
    }
    return rows;
  }
}
