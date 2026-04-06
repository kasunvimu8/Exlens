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
                BudgetProgressWidget(
                    spentPercentage: spentPercentage,
                    totalSpent: totalSpent,
                    remaining: remaining,
                    budgetAmount: budgetAmount,
                    currencyCode: store.selectedCurrency
                )
            }
        case .fixedVsVariable:
            if totalSpent > 0 {
                FixedVsVariableWidget(
                    fixedTotal: fixedTotal,
                    variableTotal: variableTotal,
                    totalSpent: totalSpent,
                    currencyCode: store.selectedCurrency
                )
            }
        case .categoryChart:
            if !breakdown.isEmpty {
                CategoryDonutWidget(
                    breakdown: breakdown,
                    totalSpent: totalSpent,
                    currencyCode: store.selectedCurrency,
                    selectedPieAngle: $selectedPieAngle
                )
            }
        case .categoryBreakdown:
            if !breakdown.isEmpty {
                CategoryBreakdownWidget(
                    breakdown: breakdown,
                    totalSpent: totalSpent,
                    currencyCode: store.selectedCurrency
                )
            }
        case .insights:
            InsightsWidget(
                monthExpenses: monthExpenses,
                totalSpent: totalSpent,
                budgetAmount: budgetAmount,
                remaining: remaining,
                spentPercentage: spentPercentage,
                breakdown: breakdown,
                fixedTotal: fixedTotal,
                currencyCode: store.selectedCurrency
            )
        case .monthlyTrendLine:
            MonthlyTrendLineWidget(
                currencyCode: store.selectedCurrency,
                trendCategoryFilter: $trendCategoryFilter,
                trendTypeFilter: $trendTypeFilter
            )
        case .categoryComparisonBar:
            CategoryComparisonBarWidget(
                selectedDate: selectedDate,
                currencyCode: store.selectedCurrency,
                selectedBarCategory: $selectedBarCategory
            )
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
}
