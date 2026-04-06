//
//  CategoryTrendsSection.swift
//  exp-app
//

import SwiftUI

struct CategoryTrend: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let currentAmount: Double
    let previousAmount: Double
    var change: Double { currentAmount - previousAmount }
    var changePercent: Double {
        guard previousAmount > 0 else { return currentAmount > 0 ? 100 : 0 }
        return (change / previousAmount) * 100
    }
    var status: TrendStatus {
        if previousAmount == 0 && currentAmount > 0 { return .new }
        if currentAmount == 0 && previousAmount > 0 { return .gone }
        if change > 0 { return .increased }
        if change < 0 { return .decreased }
        return .unchanged
    }
}

enum TrendStatus {
    case increased, decreased, unchanged, new, gone
    
    var icon: String {
        switch self {
        case .increased: return "arrow.up.circle.fill"
        case .decreased: return "arrow.down.circle.fill"
        case .unchanged: return "equal.circle.fill"
        case .new: return "plus.circle.fill"
        case .gone: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increased: return .red
        case .decreased: return .green
        case .unchanged: return .secondary
        case .new: return .orange
        case .gone: return .secondary
        }
    }
    
    var label: String {
        switch self {
        case .increased: return "Increased"
        case .decreased: return "Decreased"
        case .unchanged: return "Unchanged"
        case .new: return "New this month"
        case .gone: return "Not spent this month"
        }
    }
}

struct CategoryTrendsSection: View {
    @Environment(ExpenseStore.self) private var store
    let trends: [CategoryTrend]
    let previousMonthLabel: String
    let currentMonthLabel: String
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Trends")
                .font(.headline)
            
            Text("\(previousMonthLabel) vs \(currentMonthLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ForEach(trends) { trend in
                HStack {
                    Image(systemName: trend.icon)
                        .foregroundStyle(store.colorForCategory(trend.id))
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trend.name)
                            .font(.subheadline)
                        Text(trend.status.label)
                            .font(.caption)
                            .foregroundStyle(trend.status.color)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: trend.status.icon)
                                .font(.caption)
                                .foregroundStyle(trend.status.color)
                            Text(abs(trend.change), format: .currency(code: currencyCode))
                                .font(.subheadline.monospacedDigit())
                        }
                        if trend.previousAmount > 0 && trend.status != .unchanged {
                            Text("\(trend.changePercent >= 0 ? "+" : "")\(Int(trend.changePercent))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if trend.id != trends.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
