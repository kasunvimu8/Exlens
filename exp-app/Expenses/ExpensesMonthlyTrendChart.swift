//
//  ExpensesMonthlyTrendChart.swift
//  exp-app
//

import SwiftUI
import Charts

struct ExpensesMonthlyTrendChart: View {
    @Environment(ExpenseStore.self) private var store
    let currencyCode: String
    
    var body: some View {
        let data = store.monthlyTotals(lastMonths: 12, categoryIDs: nil, isFixed: nil)
        let budgetData: [(label: String, budget: Double)] = data.compactMap { item in
            if let b = store.budget(for: item.year, month: item.month) {
                return (label: item.label, budget: b.amount)
            } else if store.defaultBudget > 0 {
                return (label: item.label, budget: store.defaultBudget)
            }
            return nil
        }
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Monthly Spending")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if !budgetData.isEmpty {
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                            Text("Spent").font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 3) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("Budget").font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            if data.contains(where: { $0.total > 0 }) {
                Chart {
                    ForEach(data, id: \.label) { item in
                        LineMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.total),
                            series: .value("Series", "Spent")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.accentColor)
                        
                        AreaMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.total)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.accentColor.opacity(0.1).gradient)
                    }
                    
                    ForEach(budgetData, id: \.label) { item in
                        LineMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.budget),
                            series: .value("Series", "Budget")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.system(size: 8))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name).font(.system(size: 8))
                            }
                        }
                    }
                }
                .frame(height: 80)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
