import SwiftUI

struct InsightsWidget: View {
    @Environment(ExpenseStore.self) private var store
    let monthExpenses: [Expense]
    let totalSpent: Double
    let budgetAmount: Double
    let remaining: Double
    let spentPercentage: Double
    let breakdown: [(name: String, icon: String, categoryID: UUID, total: Double)]
    let fixedTotal: Double
    let currencyCode: String
    
    var body: some View {
        let insights = generateInsights()
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            
            if insights.isEmpty {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.secondary)
                    Text("Add some expenses to see insights.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(insights, id: \.message) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: insight.icon)
                            .foregroundStyle(insight.color)
                            .frame(width: 24)
                        Text(insight.message)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func generateInsights() -> [InsightItem] {
        var insights: [InsightItem] = []
        
        if budgetAmount > 0 {
            let pct = Int(spentPercentage * 100)
            if totalSpent > budgetAmount {
                insights.append(InsightItem(
                    icon: "exclamationmark.triangle.fill",
                    message: "You've exceeded your budget by \((-remaining).formatted(.currency(code: currencyCode))).",
                    color: .red
                ))
            } else if pct >= 80 {
                insights.append(InsightItem(
                    icon: "exclamationmark.circle.fill",
                    message: "You've spent \(pct)% of your monthly budget. \(remaining.formatted(.currency(code: currencyCode))) left.",
                    color: .orange
                ))
            } else if pct >= 50 {
                insights.append(InsightItem(
                    icon: "info.circle.fill",
                    message: "You've used \(pct)% of your budget with \(remaining.formatted(.currency(code: currencyCode))) remaining.",
                    color: .blue
                ))
            } else if pct > 0 {
                insights.append(InsightItem(
                    icon: "checkmark.circle.fill",
                    message: "Great! You've only used \(pct)% of your budget so far.",
                    color: .green
                ))
            }
        }
        
        if let top = breakdown.first, totalSpent > 0 {
            let pct = Int(top.total / totalSpent * 100)
            insights.append(InsightItem(
                icon: "chart.bar.fill",
                message: "\(top.name) is your largest category at \(pct)% of spending.",
                color: .purple
            ))
        }
        
        let count = monthExpenses.count
        if count > 0 {
            let avg = totalSpent / Double(count)
            insights.append(InsightItem(
                icon: "number.circle.fill",
                message: "\(count) expense\(count == 1 ? "" : "s") this month, averaging \(avg.formatted(.currency(code: currencyCode))) each.",
                color: .teal
            ))
        }
        
        if fixedTotal > 0 && totalSpent > 0 {
            let fixedPct = Int(fixedTotal / totalSpent * 100)
            insights.append(InsightItem(
                icon: "pin.circle.fill",
                message: "Fixed costs make up \(fixedPct)% of your spending (\(fixedTotal.formatted(.currency(code: currencyCode)))).",
                color: .blue
            ))
        }
        
        if budgetAmount == 0 && !monthExpenses.isEmpty {
            insights.append(InsightItem(
                icon: "target",
                message: "Set a budget to track your spending goals.",
                color: .green
            ))
        }
        
        return insights
    }
}
