//
//  ExpenseStore.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 04.04.26.
//

import SwiftUI

@Observable
class ExpenseStore {
    var expenses: [Expense] = [] {
        didSet { saveExpenses() }
    }
    
    var categories: [CustomCategory] = [] {
        didSet { saveCategories() }
    }
    
    var selectedCurrency: String = "EUR" {
        didSet { UserDefaults.standard.set(selectedCurrency, forKey: currencyKey) }
    }
    
    var defaultBudget: Double = 0 {
        didSet { UserDefaults.standard.set(defaultBudget, forKey: defaultBudgetKey) }
    }
    
    /// 0 = System, 1 = Light, 2 = Dark
    var appTheme: Int = 0 {
        didSet { UserDefaults.standard.set(appTheme, forKey: themeKey) }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    var monthlyBudgets: [MonthlyBudget] = [] {
        didSet { saveBudgets() }
    }
    
    var fixedCostTemplates: [FixedCostTemplate] = [] {
        didSet { saveFixedCostTemplates() }
    }

    var dashboardWidgets: [DashboardWidgetConfig] = [] {
        didSet { saveDashboardWidgets() }
    }

    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private let expensesKey = "expenses"
    private let categoriesKey = "categories"
    private let currencyKey = "selectedCurrency"
    private let budgetsKey = "monthlyBudgets"
    private let defaultBudgetKey = "defaultBudget"
    private let themeKey = "appTheme"
    private let fixedCostTemplatesKey = "fixedCostTemplates"
    private let dashboardWidgetsKey = "dashboardWidgets"

    init() {
        if let saved = UserDefaults.standard.string(forKey: currencyKey) {
            selectedCurrency = saved
        }
        let savedBudget = UserDefaults.standard.double(forKey: defaultBudgetKey)
        if savedBudget > 0 {
            defaultBudget = savedBudget
        }
        appTheme = UserDefaults.standard.integer(forKey: themeKey)
        loadCategories()
        loadExpenses()
        loadBudgets()
        loadFixedCostTemplates()
        loadDashboardWidgets()
        if dashboardWidgets.isEmpty {
            dashboardWidgets = Self.defaultWidgetConfig()
        }
    }
    
    static func defaultWidgetConfig() -> [DashboardWidgetConfig] {
        [
            DashboardWidgetConfig(widget: .budgetProgress, isEnabled: true),
            DashboardWidgetConfig(widget: .fixedVsVariable, isEnabled: true),
            DashboardWidgetConfig(widget: .categoryChart, isEnabled: true),
            DashboardWidgetConfig(widget: .categoryBreakdown, isEnabled: true),
            DashboardWidgetConfig(widget: .insights, isEnabled: true),
            DashboardWidgetConfig(widget: .monthlyTrendLine, isEnabled: false),
            DashboardWidgetConfig(widget: .categoryComparisonBar, isEnabled: false),
        ]
    }
    
    // MARK: - Budget Methods
    
    func budget(for year: Int, month: Int) -> MonthlyBudget? {
        monthlyBudgets.first { $0.year == year && $0.month == month }
    }
    
    func setBudget(amount: Double, year: Int, month: Int) {
        if let index = monthlyBudgets.firstIndex(where: { $0.year == year && $0.month == month }) {
            monthlyBudgets[index].amount = amount
        } else {
            monthlyBudgets.append(MonthlyBudget(year: year, month: month, amount: amount))
        }
    }
    
    func removeBudget(year: Int, month: Int) {
        monthlyBudgets.removeAll { $0.year == year && $0.month == month }
    }
    
    // MARK: - Month Query Methods
    
    func expenses(for year: Int, month: Int) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return components.year == year && components.month == month
        }
    }
    
    func totalSpent(for year: Int, month: Int) -> Double {
        expenses(for: year, month: month).reduce(0) { $0 + $1.amount }
    }
    
    func fixedCostTotal(for year: Int, month: Int) -> Double {
        expenses(for: year, month: month).filter(\.isFixed).reduce(0) { $0 + $1.amount }
    }
    
    func variableCostTotal(for year: Int, month: Int) -> Double {
        expenses(for: year, month: month).filter { !$0.isFixed }.reduce(0) { $0 + $1.amount }
    }
    
    func categoryBreakdown(for year: Int, month: Int) -> [(name: String, icon: String, categoryID: UUID, total: Double)] {
        let monthExpenses = expenses(for: year, month: month)
        var totals: [UUID: (name: String, icon: String, total: Double)] = [:]
        for expense in monthExpenses {
            let existing = totals[expense.categoryID]
            totals[expense.categoryID] = (
                name: expense.categoryName,
                icon: expense.categoryIcon,
                total: (existing?.total ?? 0) + expense.amount
            )
        }
        return totals.map { (name: $0.value.name, icon: $0.value.icon, categoryID: $0.key, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Filtered Query Methods
    
    func filteredExpenses(
        year: Int? = nil,
        month: Int? = nil,
        categoryIDs: Set<UUID>? = nil,
        isFixed: Bool? = nil,
        searchText: String = ""
    ) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            if let y = year, let m = month {
                let components = calendar.dateComponents([.year, .month], from: expense.date)
                guard components.year == y && components.month == m else { return false }
            }
            if let ids = categoryIDs, !ids.isEmpty {
                guard ids.contains(expense.categoryID) else { return false }
            }
            if let fixed = isFixed {
                guard expense.isFixed == fixed else { return false }
            }
            if !searchText.isEmpty {
                guard expense.title.localizedCaseInsensitiveContains(searchText) else { return false }
            }
            return true
        }
    }
    
    func monthlyTotals(
        lastMonths: Int = 12,
        categoryIDs: Set<UUID>? = nil,
        isFixed: Bool? = nil
    ) -> [(year: Int, month: Int, label: String, total: Double)] {
        let calendar = Calendar.current
        return (0..<lastMonths).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let filtered = filteredExpenses(year: y, month: m, categoryIDs: categoryIDs, isFixed: isFixed)
            let total = filtered.reduce(0) { $0 + $1.amount }
            let label = date.formatted(.dateTime.month(.abbreviated))
            return (year: y, month: m, label: label, total: total)
        }
    }
    
    func availableMonths() -> [(year: Int, month: Int, label: String)] {
        let calendar = Calendar.current
        var seen = Set<String>()
        var result: [(year: Int, month: Int, label: String)] = []
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let y = calendar.component(.year, from: expense.date)
            let m = calendar.component(.month, from: expense.date)
            let key = "\(y)-\(m)"
            if seen.insert(key).inserted {
                let components = DateComponents(year: y, month: m)
                let date = calendar.date(from: components) ?? expense.date
                let label = date.formatted(.dateTime.month(.abbreviated).year())
                result.append((year: y, month: m, label: label))
            }
        }
        return result
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
    }

    func delete(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
    }
    
    func deleteAllExpenses() {
        expenses.removeAll()
    }
    
    func importExpenses(_ newExpenses: [Expense]) {
        expenses.append(contentsOf: newExpenses)
        
        // Auto-set monthly budgets for imported months (uses defaultBudget or 2000 as fallback)
        let budgetAmount = defaultBudget > 0 ? defaultBudget : 2000.0
        let calendar = Calendar.current
        var monthsWithExpenses = Set<String>()
        for expense in newExpenses {
            let comps = calendar.dateComponents([.year, .month], from: expense.date)
            if let y = comps.year, let m = comps.month {
                monthsWithExpenses.insert("\(y)-\(m)")
            }
        }
        for key in monthsWithExpenses {
            let parts = key.split(separator: "-")
            if let y = Int(parts[0]), let m = Int(parts[1]) {
                if budget(for: y, month: m) == nil {
                    setBudget(amount: budgetAmount, year: y, month: m)
                }
            }
        }
    }
    
    // MARK: - Fixed Cost Template Methods

    func addFixedCostTemplate(_ template: FixedCostTemplate) {
        fixedCostTemplates.append(template)
    }

    func updateFixedCostTemplate(_ template: FixedCostTemplate) {
        if let index = fixedCostTemplates.firstIndex(where: { $0.id == template.id }) {
            fixedCostTemplates[index] = template
        }
    }

    func deleteFixedCostTemplate(id: UUID) {
        fixedCostTemplates.removeAll { $0.id == id }
    }

    /// Applies all fixed cost templates as expenses for the given month.
    /// Returns the number of expenses added.
    @discardableResult
    func applyFixedCosts(year: Int, month: Int) -> Int {
        let date = Date()

        var count = 0
        for template in fixedCostTemplates {
            let expense = Expense(
                title: template.title,
                amount: template.amount,
                date: date,
                categoryID: template.categoryID,
                categoryName: template.categoryName,
                categoryIcon: template.categoryIcon,
                isFixed: true
            )
            expenses.append(expense)
            count += 1
        }
        return count
    }

    /// Checks if fixed costs have already been applied for a given month.
    func hasFixedCostsApplied(year: Int, month: Int) -> Bool {
        let monthExpenses = expenses(for: year, month: month)
        let templateTitles = Set(fixedCostTemplates.map(\.title))
        let fixedInMonth = monthExpenses.filter { $0.isFixed && templateTitles.contains($0.title) }
        return fixedInMonth.count >= fixedCostTemplates.count && !fixedCostTemplates.isEmpty
    }

    func addCategory(_ category: CustomCategory) {
        categories.append(category)
    }
    
    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
    
    func updateCategory(_ category: CustomCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
        }
    }

    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
    
    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: categoriesKey)
        }
    }
    
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            categories = decoded
        }
    }
    
    private func saveBudgets() {
        if let data = try? JSONEncoder().encode(monthlyBudgets) {
            UserDefaults.standard.set(data, forKey: budgetsKey)
        }
    }
    
    private func loadBudgets() {
        if let data = UserDefaults.standard.data(forKey: budgetsKey),
           let decoded = try? JSONDecoder().decode([MonthlyBudget].self, from: data) {
            monthlyBudgets = decoded
        }
    }
    
    private func saveFixedCostTemplates() {
        if let data = try? JSONEncoder().encode(fixedCostTemplates) {
            UserDefaults.standard.set(data, forKey: fixedCostTemplatesKey)
        }
    }

    private func loadFixedCostTemplates() {
        if let data = UserDefaults.standard.data(forKey: fixedCostTemplatesKey),
           let decoded = try? JSONDecoder().decode([FixedCostTemplate].self, from: data) {
            fixedCostTemplates = decoded
        }
    }

    private func saveDashboardWidgets() {
        if let data = try? JSONEncoder().encode(dashboardWidgets) {
            UserDefaults.standard.set(data, forKey: dashboardWidgetsKey)
        }
    }
    
    private func loadDashboardWidgets() {
        if let data = UserDefaults.standard.data(forKey: dashboardWidgetsKey),
           let decoded = try? JSONDecoder().decode([DashboardWidgetConfig].self, from: data) {
            dashboardWidgets = decoded
        }
    }
    
    // MARK: - Locale-Aware Decimal Helpers
    
    /// The locale's decimal separator (e.g. "." or ",")
    static var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    /// Parses an amount string that may use either "," or "." as decimal separator.
    static func parseAmount(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
    
    /// Filters and sanitizes decimal input, accepting both "," and "." as decimal separators.
    /// Returns the sanitized string, or the old value if the new input is invalid.
    static func sanitizeDecimalInput(old oldValue: String, new newValue: String) -> String {
        let sep = decimalSeparator
        let otherSep = sep == "." ? "," : "."
        
        // Allow digits and both decimal separators
        var filtered = newValue.filter { "0123456789.,".contains($0) }
        
        // Normalize: replace the non-locale separator with the locale one
        filtered = filtered.replacingOccurrences(of: otherSep, with: sep)
        
        // Ensure at most one decimal separator
        let parts = filtered.components(separatedBy: sep)
        if parts.count > 2 {
            return oldValue
        }
        
        // Limit to 2 decimal places
        if parts.count == 2 && parts[1].count > 2 {
            return oldValue
        }
        
        return filtered
    }
    
    /// Formats an amount for display in a text field, using the locale's decimal separator.
    static func formatAmountForInput(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
        if decimalSeparator == "," {
            return formatted.replacingOccurrences(of: ".", with: ",")
        }
        return formatted
    }
    
    /// Locale-aware placeholder for amount fields (e.g. "0.00" or "0,00").
    static var amountPlaceholder: String {
        decimalSeparator == "," ? "0,00" : "0.00"
    }
}
