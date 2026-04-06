//
//  RecommendationsView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import SwiftUI

struct RecommendationsView: View {
    @Environment(ExpenseStore.self) private var store
    
    @State private var selectedMonth1: (year: Int, month: Int)? = nil
    @State private var selectedMonth2: (year: Int, month: Int)? = nil
    
    private var calendar: Calendar { Calendar.current }
    
    // Month 1 (right side / "current") — defaults to current month
    private var currentYear: Int { selectedMonth1?.year ?? calendar.component(.year, from: Date()) }
    private var currentMonth: Int { selectedMonth1?.month ?? calendar.component(.month, from: Date()) }
    
    // Month 2 (left side / "previous") — defaults to previous month
    private var defaultPrevDate: Date {
        calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    }
    private var prevYear: Int { selectedMonth2?.year ?? calendar.component(.year, from: defaultPrevDate) }
    private var prevMonth: Int { selectedMonth2?.month ?? calendar.component(.month, from: defaultPrevDate) }
    
    private var currentTotal: Double {
        store.totalSpent(for: currentYear, month: currentMonth)
    }
    private var previousTotal: Double {
        store.totalSpent(for: prevYear, month: prevMonth)
    }
    
    private var totalChange: Double { currentTotal - previousTotal }
    private var totalChangePercent: Double {
        guard previousTotal > 0 else { return currentTotal > 0 ? 100 : 0 }
        return (totalChange / previousTotal) * 100
    }
    
    private var currentBreakdown: [(name: String, icon: String, categoryID: UUID, total: Double)] {
        store.categoryBreakdown(for: currentYear, month: currentMonth)
    }
    private var previousBreakdown: [(name: String, icon: String, categoryID: UUID, total: Double)] {
        store.categoryBreakdown(for: prevYear, month: prevMonth)
    }
    
    private var currentMonthLabel: String {
        formatMonthLabel(year: currentYear, month: currentMonth)
    }
    private var previousMonthLabel: String {
        formatMonthLabel(year: prevYear, month: prevMonth)
    }
    
    private var categoryTrends: [CategoryTrend] {
        var allCategoryIDs = Set<UUID>()
        var currentMap: [UUID: (name: String, icon: String, total: Double)] = [:]
        var previousMap: [UUID: (name: String, icon: String, total: Double)] = [:]
        
        for item in currentBreakdown {
            allCategoryIDs.insert(item.categoryID)
            currentMap[item.categoryID] = (name: item.name, icon: item.icon, total: item.total)
        }
        for item in previousBreakdown {
            allCategoryIDs.insert(item.categoryID)
            previousMap[item.categoryID] = (name: item.name, icon: item.icon, total: item.total)
        }
        
        return allCategoryIDs.map { id in
            let current = currentMap[id]
            let previous = previousMap[id]
            return CategoryTrend(
                id: id,
                name: current?.name ?? previous?.name ?? "Unknown",
                icon: current?.icon ?? previous?.icon ?? "questionmark.circle",
                currentAmount: current?.total ?? 0,
                previousAmount: previous?.total ?? 0
            )
        }
        .sorted { abs($0.change) > abs($1.change) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if currentTotal == 0 && previousTotal == 0 {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Add expenses to see recommendations and trend analysis.")
                        )
                    } else {
                        monthComparisonSelector
                        monthOverMonthCard
                        
                        SpendingTrendChart(
                            currentYear: currentYear,
                            currentMonth: currentMonth,
                            currencyCode: store.selectedCurrency
                        )
                        
                        if !categoryTrends.isEmpty {
                            CategoryTrendsSection(
                                trends: categoryTrends,
                                previousMonthLabel: previousMonthLabel,
                                currentMonthLabel: currentMonthLabel,
                                currencyCode: store.selectedCurrency
                            )
                        }
                        
                        recommendationsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Recommendations")
        }
    }
    
    // MARK: - Helpers
    
    private func formatMonthLabel(year: Int, month: Int) -> String {
        let components = DateComponents(year: year, month: month)
        let date = calendar.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.abbreviated))
    }
    
    private func formatMonthYearLabel(year: Int, month: Int) -> String {
        let components = DateComponents(year: year, month: month)
        let date = calendar.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
    
    // MARK: - Month Comparison Selector
    
    private var monthComparisonSelector: some View {
        HStack {
            Menu {
                ForEach(store.availableMonths(), id: \.label) { item in
                    Button(item.label) {
                        selectedMonth2 = (year: item.year, month: item.month)
                    }
                }
                Divider()
                Button("Reset to Default") { selectedMonth2 = nil }
            } label: {
                HStack(spacing: 4) {
                    Text(formatMonthYearLabel(year: prevYear, month: prevMonth))
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(store.availableMonths(), id: \.label) { item in
                    Button(item.label) {
                        selectedMonth1 = (year: item.year, month: item.month)
                    }
                }
                Divider()
                Button("Reset to Default") { selectedMonth1 = nil }
            } label: {
                HStack(spacing: 4) {
                    Text(formatMonthYearLabel(year: currentYear, month: currentMonth))
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Month over Month Card
    
    private var monthOverMonthCard: some View {
        VStack(spacing: 16) {
            Text("Month over Month")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(previousMonthLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(previousTotal, format: .currency(code: store.selectedCurrency))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 4) {
                    Text(currentMonthLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentTotal, format: .currency(code: store.selectedCurrency))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            
            HStack(spacing: 6) {
                Image(systemName: totalChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())
                    .foregroundStyle(totalChange > 0 ? .red : totalChange < 0 ? .green : .secondary)
                
                Text(abs(totalChange), format: .currency(code: store.selectedCurrency))
                    .font(.subheadline.bold())
                    .foregroundStyle(totalChange > 0 ? .red : totalChange < 0 ? .green : .secondary)
                
                Text("(\(Int(abs(totalChangePercent)))%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(totalChange > 0 ? "Spending increased" : totalChange < 0 ? "Spending decreased" : "No change")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Recommendations
    
    private var recommendationsSection: some View {
        let recommendations = generateRecommendations()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            if recommendations.isEmpty {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.secondary)
                    Text("Keep tracking expenses to get personalized recommendations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(recommendations, id: \.message) { rec in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: rec.icon)
                            .foregroundStyle(rec.color)
                            .frame(width: 24)
                        Text(rec.message)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func generateRecommendations() -> [InsightItem] {
        var recs: [InsightItem] = []
        let currency = store.selectedCurrency
        
        if previousTotal > 0 && currentTotal > 0 {
            if totalChange > 0 {
                recs.append(InsightItem(
                    icon: "exclamationmark.triangle.fill",
                    message: "Your spending increased by \(abs(totalChange).formatted(.currency(code: currency))) (\(Int(abs(totalChangePercent)))%) compared to last month. Review your expenses to find areas to cut back.",
                    color: .red
                ))
            } else if totalChange < 0 {
                recs.append(InsightItem(
                    icon: "hand.thumbsup.fill",
                    message: "Great job! You spent \(abs(totalChange).formatted(.currency(code: currency))) (\(Int(abs(totalChangePercent)))%) less than last month.",
                    color: .green
                ))
            }
        }
        
        let increases = categoryTrends.filter { $0.status == .increased }.prefix(2)
        for trend in increases {
            recs.append(InsightItem(
                icon: "arrow.up.right.circle.fill",
                message: "\(trend.name) spending went up by \(abs(trend.change).formatted(.currency(code: currency))) (\(Int(abs(trend.changePercent)))%). Consider setting a limit for this category.",
                color: .orange
            ))
        }
        
        let decreases = categoryTrends.filter { $0.status == .decreased }.prefix(1)
        for trend in decreases {
            recs.append(InsightItem(
                icon: "arrow.down.right.circle.fill",
                message: "You reduced \(trend.name) spending by \(abs(trend.change).formatted(.currency(code: currency))). Keep it up!",
                color: .green
            ))
        }
        
        let newCats = categoryTrends.filter { $0.status == .new }
        if !newCats.isEmpty {
            let names = newCats.map(\.name).joined(separator: ", ")
            recs.append(InsightItem(
                icon: "sparkles",
                message: "New spending this month: \(names). Watch these to make sure they don't become recurring surprises.",
                color: .purple
            ))
        }
        
        let currentBudget = store.budget(for: currentYear, month: currentMonth)?.amount ?? 0
        let prevBudget = store.budget(for: prevYear, month: prevMonth)?.amount ?? 0
        
        if currentBudget > 0 && prevBudget > 0 {
            let currentRatio = currentTotal / currentBudget
            let prevRatio = previousTotal / prevBudget
            if currentRatio > prevRatio && currentRatio > 0.8 {
                recs.append(InsightItem(
                    icon: "chart.line.uptrend.xyaxis",
                    message: "You're using a larger portion of your budget compared to last month. Consider adjusting your spending or increasing your budget.",
                    color: .orange
                ))
            } else if currentRatio < prevRatio && currentRatio < 0.7 {
                recs.append(InsightItem(
                    icon: "checkmark.seal.fill",
                    message: "You're staying well within budget this month, better than last month. Excellent discipline!",
                    color: .green
                ))
            }
        }
        
        let currentFixed = store.fixedCostTotal(for: currentYear, month: currentMonth)
        let prevFixed = store.fixedCostTotal(for: prevYear, month: prevMonth)
        if currentFixed > 0 && currentTotal > 0 {
            let fixedPct = Int(currentFixed / currentTotal * 100)
            if prevFixed > 0 {
                let fixedChange = currentFixed - prevFixed
                if fixedChange > 0 {
                    recs.append(InsightItem(
                        icon: "pin.circle.fill",
                        message: "Fixed costs increased by \(abs(fixedChange).formatted(.currency(code: currency))). Review recurring expenses like subscriptions or rent.",
                        color: .orange
                    ))
                }
            }
            if fixedPct > 60 {
                recs.append(InsightItem(
                    icon: "lock.circle.fill",
                    message: "\(fixedPct)% of your spending is fixed costs. Look for variable expenses you can reduce for more flexibility.",
                    color: .blue
                ))
            }
        }
        
        let data3 = (0..<3).compactMap { offset -> Double? in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            return store.totalSpent(for: y, month: m)
        }
        if data3.count == 3 && data3[2] > 0 && data3[1] > 0 && data3[0] > 0 {
            if data3[0] > data3[1] && data3[1] > data3[2] {
                recs.append(InsightItem(
                    icon: "exclamationmark.circle.fill",
                    message: "Your spending has been increasing for 3 consecutive months. Take a closer look at your habits to reverse the trend.",
                    color: .red
                ))
            } else if data3[0] < data3[1] && data3[1] < data3[2] {
                recs.append(InsightItem(
                    icon: "star.fill",
                    message: "Your spending has been decreasing for 3 consecutive months. Fantastic progress!",
                    color: .green
                ))
            }
        }
        
        return recs
    }
}
