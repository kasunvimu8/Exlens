import SwiftUI
import Charts

struct CategoryDonutWidget: View {
    @Environment(ExpenseStore.self) private var store
    let breakdown: [(name: String, icon: String, categoryID: UUID, total: Double)]
    let totalSpent: Double
    let currencyCode: String
    @Binding var selectedPieAngle: Double?
    
    private var selectedPieCategory: (name: String, icon: String, categoryID: UUID, total: Double)? {
        guard let angle = selectedPieAngle else { return nil }
        var cumulative = 0.0
        for item in breakdown {
            cumulative += item.total
            if angle <= cumulative {
                return item
            }
        }
        return breakdown.last
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
            
            Chart(breakdown, id: \.categoryID) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(store.colorForCategory(item.categoryID))
                .cornerRadius(4)
                .opacity(selectedPieCategory == nil || selectedPieCategory?.categoryID == item.categoryID ? 1.0 : 0.4)
            }
            .chartAngleSelection(value: $selectedPieAngle)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry[chartProxy.plotFrame!]
                    VStack(spacing: 2) {
                        if let selected = selectedPieCategory {
                            Image(systemName: selected.icon)
                                .font(.title3)
                                .foregroundStyle(store.colorForCategory(selected.categoryID))
                            Text(selected.name)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text(selected.total, format: .currency(code: currencyCode))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        } else {
                            Text(totalSpent, format: .currency(code: currencyCode))
                                .font(.callout.bold().monospacedDigit())
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(height: 220)
            
            // Legend
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                ForEach(breakdown, id: \.categoryID) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.colorForCategory(item.categoryID))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(item.total, format: .currency(code: currencyCode))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .opacity(selectedPieCategory == nil || selectedPieCategory?.categoryID == item.categoryID ? 1.0 : 0.4)
                    .onTapGesture {
                        if selectedPieCategory?.categoryID == item.categoryID {
                            selectedPieAngle = nil
                        } else {
                            var cumulative = 0.0
                            for b in breakdown {
                                cumulative += b.total
                                if b.categoryID == item.categoryID {
                                    selectedPieAngle = cumulative - item.total / 2
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
