//
//  SpendingTrendChart.swift
//  exp-app
//

import SwiftUI
import Charts

struct SpendingTrendChart: View {
    @Environment(ExpenseStore.self) private var store
    let currentYear: Int
    let currentMonth: Int
    let currencyCode: String
    
    private var calendar: Calendar { Calendar.current }
    
    private struct MonthData: Identifiable {
        let id = UUID()
        let label: String
        let total: Double
        let year: Int
        let month: Int
    }
    
    private var last6MonthsData: [MonthData] {
        (0..<6).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let total = store.totalSpent(for: y, month: m)
            let label = date.formatted(.dateTime.month(.abbreviated))
            return MonthData(label: label, total: total, year: y, month: m)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .font(.headline)
            
            Chart(last6MonthsData) { item in
                BarMark(
                    x: .value("Month", item.label),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(
                    item.year == currentYear && item.month == currentMonth
                        ? Color.accentColor.gradient
                        : Color.accentColor.opacity(0.4).gradient
                )
                .cornerRadius(4)
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
            .frame(height: 180)
            
            if last6MonthsData.filter({ $0.total > 0 }).count >= 3 {
                let recent3 = last6MonthsData.suffix(3)
                let older3 = last6MonthsData.prefix(3)
                let recentAvg = recent3.map(\.total).reduce(0, +) / max(Double(recent3.count), 1)
                let olderAvg = older3.map(\.total).reduce(0, +) / max(Double(older3.count), 1)
                
                if olderAvg > 0 {
                    let trendPct = ((recentAvg - olderAvg) / olderAvg) * 100
                    HStack(spacing: 6) {
                        Image(systemName: trendPct >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(trendPct > 5 ? .red : trendPct < -5 ? .green : .secondary)
                        Text("Overall trend: \(trendPct >= 0 ? "+" : "")\(Int(trendPct))% over 6 months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
