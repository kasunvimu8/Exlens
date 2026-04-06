import SwiftUI
import Charts

struct FixedVsVariableWidget: View {
    @Environment(ExpenseStore.self) private var store
    let fixedTotal: Double
    let variableTotal: Double
    let totalSpent: Double
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fixed vs Variable")
                .font(.headline)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    Text("Fixed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(fixedTotal, format: .currency(code: currencyCode))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    Text("Variable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(variableTotal, format: .currency(code: currencyCode))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            
            let fixedData = store.monthlyTotals(lastMonths: 6, categoryIDs: nil, isFixed: true)
            let variableData = store.monthlyTotals(lastMonths: 6, categoryIDs: nil, isFixed: false)
            
            Chart {
                ForEach(fixedData, id: \.label) { item in
                    LineMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(by: .value("Type", "Fixed"))
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                    
                    AreaMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(by: .value("Type", "Fixed"))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.1)
                }
                
                ForEach(variableData, id: \.label) { item in
                    LineMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(by: .value("Type", "Variable"))
                    .interpolationMethod(.catmullRom)
                    .symbol(.diamond)
                    
                    AreaMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(by: .value("Type", "Variable"))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.1)
                }
            }
            .chartForegroundStyleScale([
                "Fixed": Color.accentColor,
                "Variable": Color.orange
            ])
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
            .frame(height: 160)
            
            if totalSpent > 0 {
                let fixedPct = Int(fixedTotal / totalSpent * 100)
                Text("\(fixedPct)% of your spending is fixed costs this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
