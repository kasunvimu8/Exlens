//
//  DashboardView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    
    @State private var selectedDate = Date()
    @State private var showingBudgetEditor = false
    @State private var showingCustomize = false
    @State private var showingMonthPicker = false
    @State private var trendCategoryFilter: Set<UUID> = []
    @State private var trendTypeFilter: Bool? = nil
    @State private var selectedPieAngle: Double?
    @State private var selectedBarCategory: String?
    
    private var calendar: Calendar { Calendar.current }
    private var selectedYear: Int { calendar.component(.year, from: selectedDate) }
    private var selectedMonth: Int { calendar.component(.month, from: selectedDate) }
    
    private var monthExpenses: [Expense] {
        store.expenses(for: selectedYear, month: selectedMonth)
    }
    
    private var totalSpent: Double {
        store.totalSpent(for: selectedYear, month: selectedMonth)
    }
    
    private var budgetAmount: Double {
        store.budget(for: selectedYear, month: selectedMonth)?.amount ?? 0
    }
    
    private var remaining: Double {
        budgetAmount - totalSpent
    }
    
    private var spentPercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(totalSpent / budgetAmount, 1.5)
    }
    
    private var breakdown: [(name: String, icon: String, categoryID: UUID, total: Double)] {
        store.categoryBreakdown(for: selectedYear, month: selectedMonth)
    }
    
    private var fixedTotal: Double {
        store.fixedCostTotal(for: selectedYear, month: selectedMonth)
    }
    
    private var variableTotal: Double {
        store.variableCostTotal(for: selectedYear, month: selectedMonth)
    }
    
    private var monthLabel: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector
                    budgetSummaryCard
                    
                    ForEach(store.dashboardWidgets.filter(\.isEnabled)) { config in
                        widgetView(for: config.widget)
                    }
                }
                .padding()
                .animation(.default, value: store.dashboardWidgets.map(\.isEnabled))
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomize = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) {
                BudgetEditorView(
                    year: selectedYear,
                    month: selectedMonth,
                    currentAmount: budgetAmount
                )
            }
            .sheet(isPresented: $showingCustomize) {
                DashboardCustomizeView()
            }
        }
    }
    
    @ViewBuilder
    private func widgetView(for widget: DashboardWidget) -> some View {
        switch widget {
        case .budgetProgress:
            if budgetAmount > 0 {
                budgetProgressSection
            }
        case .fixedVsVariable:
            if totalSpent > 0 {
                fixedVsVariableSection
            }
        case .categoryChart:
            if !breakdown.isEmpty {
                categoryChartSection
            }
        case .categoryBreakdown:
            if !breakdown.isEmpty {
                categoryBreakdownList
            }
        case .insights:
            insightsSection
        case .monthlyTrendLine:
            monthlyTrendLineSection
        case .categoryComparisonBar:
            categoryComparisonBarSection
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button {
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            
            Spacer()
            
            Button {
                showingMonthPicker = true
            } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(monthLabel)
                            .font(.title3.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                    }
                    if isCurrentMonth {
                        Text("Current Month")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                let next = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                if next <= Date() {
                    selectedDate = next
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(isCurrentMonth)
        }
        .padding(.horizontal, 4)
        .sheet(isPresented: $showingMonthPicker) {
            MonthYearPickerView(selectedDate: $selectedDate)
                .presentationDetents([.height(320)])
        }
    }
    
    // MARK: - Budget Summary Card
    
    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            if budgetAmount > 0 {
                HStack(spacing: 0) {
                    summaryItem(
                        title: "Spent",
                        amount: totalSpent,
                        color: .primary
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    summaryItem(
                        title: "Budget",
                        amount: budgetAmount,
                        color: .secondary
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    summaryItem(
                        title: "Remaining",
                        amount: remaining,
                        color: remaining >= 0 ? .green : .red
                    )
                }
            } else {
                VStack(spacing: 8) {
                    Text(totalSpent, format: .currency(code: store.selectedCurrency))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(totalSpent > 0 ? .primary : .secondary)
                    
                    Text(monthExpenses.isEmpty ? "No expenses yet" : "\(monthExpenses.count) expense\(monthExpenses.count == 1 ? "" : "s") this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Button {
                showingBudgetEditor = true
            } label: {
                Label(
                    budgetAmount > 0 ? "Edit Budget" : "Set Monthly Budget",
                    systemImage: budgetAmount > 0 ? "pencil.circle.fill" : "plus.circle.fill"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func summaryItem(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount, format: .currency(code: store.selectedCurrency))
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Budget Progress
    
    private var budgetProgressSection: some View {
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
                    Text(totalSpent, format: .currency(code: store.selectedCurrency))
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(totalSpent > budgetAmount ? .red : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(remaining, format: .currency(code: store.selectedCurrency))
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
    
    // MARK: - Fixed vs Variable
    
    private var fixedVsVariableSection: some View {
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
                    Text(fixedTotal, format: .currency(code: store.selectedCurrency))
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
                    Text(variableTotal, format: .currency(code: store.selectedCurrency))
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
                            Text(amount, format: .currency(code: store.selectedCurrency))
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
    
    // MARK: - Category Donut Chart
    
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
    
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
            
            Chart(breakdown, id: \.categoryID) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(colorForCategory(item.categoryID))
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
                                .foregroundStyle(colorForCategory(selected.categoryID))
                            Text(selected.name)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text(selected.total, format: .currency(code: store.selectedCurrency))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        } else {
                            Text(totalSpent, format: .currency(code: store.selectedCurrency))
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
                            .fill(colorForCategory(item.categoryID))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(item.total, format: .currency(code: store.selectedCurrency))
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
    
    private func colorForCategory(_ categoryID: UUID) -> Color {
        if let category = store.categories.first(where: { $0.id == categoryID }) {
            return Color.fromString(category.color)
        }
        let palette: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .cyan, .brown, .indigo, .teal]
        return palette[abs(categoryID.hashValue) % palette.count]
    }
    
    // MARK: - Category Breakdown List
    
    private var categoryBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Details")
                .font(.headline)
            
            ForEach(breakdown, id: \.categoryID) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.body)
                        .foregroundStyle(colorForCategory(item.categoryID))
                        .frame(width: 34, height: 34)
                        .background(colorForCategory(item.categoryID).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                        if totalSpent > 0 {
                            Text("\(Int(item.total / totalSpent * 100))% of total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.total, format: .currency(code: store.selectedCurrency))
                        .font(.body.monospacedDigit())
                }
                
                if item.categoryID != breakdown.last?.categoryID {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        let insights = generateInsights()
        
        return VStack(alignment: .leading, spacing: 12) {
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
                    message: "You've exceeded your budget by \((-remaining).formatted(.currency(code: store.selectedCurrency))).",
                    color: .red
                ))
            } else if pct >= 80 {
                insights.append(InsightItem(
                    icon: "exclamationmark.circle.fill",
                    message: "You've spent \(pct)% of your monthly budget. \(remaining.formatted(.currency(code: store.selectedCurrency))) left.",
                    color: .orange
                ))
            } else if pct >= 50 {
                insights.append(InsightItem(
                    icon: "info.circle.fill",
                    message: "You've used \(pct)% of your budget with \(remaining.formatted(.currency(code: store.selectedCurrency))) remaining.",
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
                message: "\(count) expense\(count == 1 ? "" : "s") this month, averaging \(avg.formatted(.currency(code: store.selectedCurrency))) each.",
                color: .teal
            ))
        }
        
        if fixedTotal > 0 && totalSpent > 0 {
            let fixedPct = Int(fixedTotal / totalSpent * 100)
            insights.append(InsightItem(
                icon: "pin.circle.fill",
                message: "Fixed costs make up \(fixedPct)% of your spending (\(fixedTotal.formatted(.currency(code: store.selectedCurrency)))).",
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
    
    // MARK: - Monthly Trend Line Chart
    
    private var monthlyTrendLineSection: some View {
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
                            Text(amount, format: .currency(code: store.selectedCurrency))
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
    
    // MARK: - Category Comparison Bar Chart
    
    private var categoryComparisonBarSection: some View {
        let prevDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        let prevYear = calendar.component(.year, from: prevDate)
        let prevMonth = calendar.component(.month, from: prevDate)
        
        let currentBreakdown = store.categoryBreakdown(for: selectedYear, month: selectedMonth)
        let previousBreakdown = store.categoryBreakdown(for: prevYear, month: prevMonth)
        
        let currentLabel = selectedDate.formatted(.dateTime.month(.abbreviated))
        let previousLabel = prevDate.formatted(.dateTime.month(.abbreviated))
        
        var allCategories: [(name: String, categoryID: UUID)] = []
        var seen = Set<UUID>()
        for item in currentBreakdown + previousBreakdown {
            if seen.insert(item.categoryID).inserted {
                allCategories.append((name: item.name, categoryID: item.categoryID))
            }
        }
        
        let currentMap = Dictionary(uniqueKeysWithValues: currentBreakdown.map { ($0.categoryID, $0.total) })
        let previousMap = Dictionary(uniqueKeysWithValues: previousBreakdown.map { ($0.categoryID, $0.total) })
        
        struct CategoryMonthData: Identifiable {
            let id = UUID()
            let categoryName: String
            let monthLabel: String
            let amount: Double
        }
        
        var chartData: [CategoryMonthData] = []
        for cat in allCategories {
            if let val = previousMap[cat.categoryID], val > 0 {
                chartData.append(CategoryMonthData(categoryName: cat.name, monthLabel: previousLabel, amount: val))
            }
            if let val = currentMap[cat.categoryID], val > 0 {
                chartData.append(CategoryMonthData(categoryName: cat.name, monthLabel: currentLabel, amount: val))
            }
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Category Comparison")
                .font(.headline)
            
            Text("\(previousLabel) vs \(currentLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if chartData.isEmpty {
                Text("No data to compare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Category", item.categoryName),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(by: .value("Month", item.monthLabel))
                    .position(by: .value("Month", item.monthLabel))
                    .cornerRadius(4)
                    .opacity(selectedBarCategory == nil || selectedBarCategory == item.categoryName ? 1.0 : 0.4)
                }
                .chartXSelection(value: $selectedBarCategory)
                .chartForegroundStyleScale([
                    previousLabel: Color.accentColor.opacity(0.5),
                    currentLabel: Color.accentColor
                ])
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: store.selectedCurrency))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                
                if let selected = selectedBarCategory {
                    let currentAmt = chartData.first(where: { $0.categoryName == selected && $0.monthLabel == currentLabel })?.amount
                    let previousAmt = chartData.first(where: { $0.categoryName == selected && $0.monthLabel == previousLabel })?.amount
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selected)
                            .font(.caption.bold())
                        HStack(spacing: 16) {
                            if let prev = previousAmt {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.accentColor.opacity(0.5)).frame(width: 8, height: 8)
                                    Text("\(previousLabel): \(prev, format: .currency(code: store.selectedCurrency))")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if let curr = currentAmt {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                                    Text("\(currentLabel): \(curr, format: .currency(code: store.selectedCurrency))")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct InsightItem {
    let icon: String
    let message: String
    let color: Color
}

struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerMonth: Int
    @State private var pickerYear: Int
    
    private let months = Calendar.current.monthSymbols
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    
    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let cal = Calendar.current
        _pickerMonth = State(initialValue: cal.component(.month, from: selectedDate.wrappedValue))
        _pickerYear = State(initialValue: cal.component(.year, from: selectedDate.wrappedValue))
    }
    
    private var yearRange: [Int] {
        Array((currentYear - 10)...currentYear)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("Month", selection: $pickerMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(months[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Year", selection: $pickerYear) {
                        ForEach(yearRange, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)
                
                Button {
                    if let date = Calendar.current.date(from: DateComponents(year: pickerYear, month: pickerMonth, day: 1)) {
                        if date <= Date() {
                            selectedDate = date
                        }
                    }
                    dismiss()
                } label: {
                    Text("Select")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
