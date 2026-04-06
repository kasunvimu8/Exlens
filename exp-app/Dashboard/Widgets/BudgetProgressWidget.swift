import SwiftUI

struct BudgetProgressWidget: View {
    let spentPercentage: Double
    let totalSpent: Double
    let remaining: Double
    let budgetAmount: Double
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Progress")
                .font(.headline)
            
            Gauge(value: min(spentPercentage, 1.0)) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(spentPercentage * 100))%")
                    .font(.system(.caption, design: .rounded, weight: .bold))
            } minimumValueLabel: {
                Text("0%")
                    .font(.caption2)
            } maximumValueLabel: {
                Text("100%")
                    .font(.caption2)
            }
            .gaugeStyle(.linearCapacity)
            .tint(gaugeColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalSpent, format: .currency(code: currencyCode))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(totalSpent > budgetAmount ? .red : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(remaining, format: .currency(code: currencyCode))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(remaining >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var gaugeColor: Color {
        if spentPercentage < 0.5 { return .green }
        if spentPercentage < 0.8 { return .yellow }
        return .red
    }
}
