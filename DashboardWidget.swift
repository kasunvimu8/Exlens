//
//  DashboardWidget.swift
//  exp-app
//

import Foundation

enum DashboardWidget: String, Codable, CaseIterable, Identifiable {
    case budgetProgress
    case fixedVsVariable
    case categoryChart
    case categoryBreakdown
    case insights
    case monthlyTrendLine
    case categoryComparisonBar
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .budgetProgress:       return "Budget Progress"
        case .fixedVsVariable:      return "Fixed vs Variable"
        case .categoryChart:        return "Category Chart"
        case .categoryBreakdown:    return "Category Details"
        case .insights:             return "Insights"
        case .monthlyTrendLine:     return "Monthly Trend"
        case .categoryComparisonBar: return "Category Comparison"
        }
    }
    
    var icon: String {
        switch self {
        case .budgetProgress:       return "gauge.with.needle"
        case .fixedVsVariable:      return "arrow.triangle.swap"
        case .categoryChart:        return "chart.pie"
        case .categoryBreakdown:    return "list.bullet"
        case .insights:             return "lightbulb"
        case .monthlyTrendLine:     return "chart.xyaxis.line"
        case .categoryComparisonBar: return "chart.bar"
        }
    }
}

struct DashboardWidgetConfig: Codable, Identifiable {
    var id: String { widget.rawValue }
    var widget: DashboardWidget
    var isEnabled: Bool
}
