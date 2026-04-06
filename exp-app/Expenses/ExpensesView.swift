//
//  ExpensesView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import SwiftUI
import Charts

struct ExpensesView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showingAddExpense = false
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var searchText = ""
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var selectedMonthYear: (year: Int, month: Int)? = {
        let now = Date()
        let cal = Calendar.current
        return (year: cal.component(.year, from: now), month: cal.component(.month, from: now))
    }()
    @State private var typeFilter: ExpenseTypeFilter = .all
    @State private var showingBreakdown = false
    
    enum ExpenseTypeFilter: String, CaseIterable {
        case all = "All"
        case fixed = "Fixed"
        case variable = "Variable"
    }
    
    private var filteredExpenses: [Expense] {
        store.filteredExpenses(
            year: selectedMonthYear?.year,
            month: selectedMonthYear?.month,
            categoryIDs: selectedCategoryIDs.isEmpty ? nil : selectedCategoryIDs,
            isFixed: typeFilter == .all ? nil : typeFilter == .fixed,
            searchText: searchText
        )
        .sorted { $0.date > $1.date }
    }
    
    private var filteredTotal: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var filteredFixedTotal: Double {
        filteredExpenses.filter(\.isFixed).reduce(0) { $0 + $1.amount }
    }
    
    private var filteredVariableTotal: Double {
        filteredExpenses.filter { !$0.isFixed }.reduce(0) { $0 + $1.amount }
    }
    
    private var isNonDefaultMonth: Bool {
        guard let my = selectedMonthYear else { return false }
        let now = Date()
        let cal = Calendar.current
        return my.year != cal.component(.year, from: now) || my.month != cal.component(.month, from: now)
    }
    
    private var hasActiveFilters: Bool {
        !selectedCategoryIDs.isEmpty || isNonDefaultMonth || typeFilter != .all || !searchText.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ExpensesMonthlyTrendChart(currencyCode: store.selectedCurrency)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                List {
                    Section {
                        Button {
                            withAnimation {
                                showingBreakdown.toggle()
                            }
                        } label: {
                            HStack {
                                Text(hasActiveFilters ? "Filtered Total" : "Total")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(filteredTotal, format: .currency(code: store.selectedCurrency))
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(showingBreakdown ? 180 : 0))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        
                        if showingBreakdown {
                            HStack {
                                Label("Fixed", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(filteredFixedTotal, format: .currency(code: store.selectedCurrency))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            HStack {
                                Label("Variable", systemImage: "arrow.up.arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(filteredVariableTotal, format: .currency(code: store.selectedCurrency))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Section(hasActiveFilters ? "Filtered Expenses (\(filteredExpenses.count))" : "Recent Expenses") {
                        if filteredExpenses.isEmpty {
                            ContentUnavailableView(
                                hasActiveFilters ? "No Matching Expenses" : "No Expenses",
                                systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "tray",
                                description: Text(hasActiveFilters ? "Try adjusting your filters." : "Tap + to add your first expense.")
                            )
                        } else {
                            ForEach(filteredExpenses) { expense in
                                expenseRow(expense)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            store.deleteExpense(id: expense.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .animation(.default, value: typeFilter)
            .animation(.default, value: selectedCategoryIDs)
            .searchable(text: $searchText, prompt: "Search expenses")
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button {
                            showingImport = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            showingExport = true
                        } label: {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        .disabled(store.expenses.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingImport) {
                CSVImportView()
            }
            .sheet(isPresented: $showingExport) {
                CSVExportShareSheet(fileURL: ExportHelper.generateExportURL(expenses: store.expenses))
            }
        }
    }
    
    // MARK: - Expense Row
    
    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Image(systemName: expense.categoryIcon)
                .font(.body)
                .foregroundStyle(store.colorForCategory(expense.categoryID))
                .frame(width: 36, height: 36)
                .background(store.colorForCategory(expense.categoryID).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.body)
                HStack(spacing: 4) {
                    Text(expense.categoryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\u{2022}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expense.date, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if expense.isFixed {
                        Text("Fixed")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
            }

            Spacer()

            Text(expense.amount, format: .currency(code: store.selectedCurrency))
                .font(.body.monospacedDigit())
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExpenseTypeFilter.allCases, id: \.self) { type in
                    Button {
                        typeFilter = type
                    } label: {
                        Text(type.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(typeFilter == type ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                            .foregroundStyle(typeFilter == type ? Color.accentColor : .primary)
                            .clipShape(Capsule())
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                Menu {
                    Button("All Months") { selectedMonthYear = nil }
                    Divider()
                    ForEach(store.availableMonths(), id: \.label) { item in
                        Button(item.label) {
                            selectedMonthYear = (year: item.year, month: item.month)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMonthYear != nil ? monthLabel : "Month")
                            .font(.caption.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedMonthYear != nil ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                    .foregroundStyle(selectedMonthYear != nil ? Color.accentColor : .primary)
                    .clipShape(Capsule())
                }
                
                Menu {
                    Button("All Categories") { selectedCategoryIDs = [] }
                    Divider()
                    ForEach(store.categories) { cat in
                        Button {
                            if selectedCategoryIDs.contains(cat.id) {
                                selectedCategoryIDs.remove(cat.id)
                            } else {
                                selectedCategoryIDs.insert(cat.id)
                            }
                        } label: {
                            HStack {
                                Label(cat.name, systemImage: cat.icon)
                                if selectedCategoryIDs.contains(cat.id) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategoryIDs.isEmpty ? "Category" : "\(selectedCategoryIDs.count) selected")
                            .font(.caption.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!selectedCategoryIDs.isEmpty ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                    .foregroundStyle(!selectedCategoryIDs.isEmpty ? Color.accentColor : .primary)
                    .clipShape(Capsule())
                }
                
                if hasActiveFilters {
                    Button {
                        searchText = ""
                        selectedCategoryIDs = []
                        selectedMonthYear = nil
                        typeFilter = .all
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var monthLabel: String {
        guard let my = selectedMonthYear else { return "Month" }
        let components = DateComponents(year: my.year, month: my.month)
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}
