import SwiftUI
import Charts

struct MonthlyTrendLineWidget: View {
    @Environment(ExpenseStore.self) private var store
    let currencyCode: String
    @Binding var trendCategoryFilter: Set<UUID>
    @Binding var trendTypeFilter: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Trend")
                    .font(.headline)
                Spacer()
                Menu {
                    Section("Type") {
                        Button { trendTypeFilter = nil } label: {
                            HStack {
                                Text("All")
                                if trendTypeFilter == nil { Image(systemName: "checkmark") }
                            }
                        }
                        Button { trendTypeFilter = true } label: {
                            HStack {
                                Text("Fixed Only")
                                if trendTypeFilter == true { Image(systemName: "checkmark") }
                            }
                        }
                        Button { trendTypeFilter = false } label: {
                            HStack {
                                Text("Variable Only")
                                if trendTypeFilter == false { Image(systemName: "checkmark") }
                            }
                        }
                    }
                    Section("Categories") {
                        Button("All Categories") { trendCategoryFilter = [] }
                        ForEach(store.categories) { cat in
                            Button {
                                if trendCategoryFilter.contains(cat.id) {
                                    trendCategoryFilter.remove(cat.id)
                                } else {
                                    trendCategoryFilter.insert(cat.id)
                                }
                            } label: {
                                HStack {
                                    Label(cat.name, systemImage: cat.icon)
                                    if trendCategoryFilter.contains(cat.id) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                        .foregroundStyle(
                            trendCategoryFilter.isEmpty && trendTypeFilter == nil
                                ? Color.secondary : Color.accentColor
                        )
                }
            }
            
            let data = store.monthlyTotals(
                lastMonths: 12,
                categoryIDs: trendCategoryFilter.isEmpty ? nil : trendCategoryFilter,
                isFixed: trendTypeFilter
            )
            
            Chart(data, id: \.label) { item in
                LineMark(
                    x: .value("Month", item.label),
                    y: .value("Amount", item.total)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor.gradient)
                
                AreaMark(
                    x: .value("Month", item.label),
                    y: .value("Amount", item.total)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor.opacity(0.1).gradient)
                
                PointMark(
                    x: .value("Month", item.label),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount, format: .currency(code: currencyCode))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            if !trendCategoryFilter.isEmpty || trendTypeFilter != nil {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.caption2)
                    if let fixed = trendTypeFilter {
                        Text(fixed ? "Fixed only" : "Variable only")
                            .font(.caption)
                    }
                    if !trendCategoryFilter.isEmpty {
                        Text("\(trendCategoryFilter.count) categories")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
