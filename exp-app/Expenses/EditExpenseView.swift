//
//  EditExpenseView.swift
//  exp-app
//

import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    let expense: Expense
    
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var selectedCategory: CustomCategory?
    @State private var isFixed: Bool
    @FocusState private var amountFieldFocused: Bool
    
    init(expense: Expense) {
        self.expense = expense
        _title = State(initialValue: expense.title)
        _amount = State(initialValue: ExpenseStore.formatAmountForInput(expense.amount))
        _date = State(initialValue: expense.date)
        _isFixed = State(initialValue: expense.isFixed)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text(store.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField(ExpenseStore.amountPlaceholder, text: $amount)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .focused($amountFieldFocused)
                            .onChange(of: amount) { oldValue, newValue in
                                amount = ExpenseStore.sanitizeDecimalInput(old: oldValue, new: newValue)
                            }
                    }
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Type") {
                    Picker("Expense Type", selection: $isFixed) {
                        Text("Variable").tag(false)
                        Text("Fixed").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    if store.categories.isEmpty {
                        Text("No categories available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(nil as CustomCategory?)
                            ForEach(store.categories) { cat in
                                HStack(spacing: 10) {
                                    Image(systemName: cat.icon)
                                        .foregroundStyle(Color.fromString(cat.color))
                                    Text(cat.name)
                                }
                                .tag(cat as CustomCategory?)
                            }
                        }
#if os(iOS)
                        .pickerStyle(.navigationLink)
#endif
                    }
                }
            }
            .navigationTitle("Edit Expense")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isValidInput)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            amountFieldFocused = false
                        }
                    }
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = store.categories.first(where: { $0.id == expense.categoryID })
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard !title.isEmpty,
              let value = ExpenseStore.parseAmount(amount),
              value > 0,
              selectedCategory != nil else {
            return false
        }
        return true
    }
    
    private func saveExpense() {
        guard let value = ExpenseStore.parseAmount(amount),
              let category = selectedCategory else { return }
        
        var updated = expense
        updated.title = title
        updated.amount = value
        updated.date = date
        updated.categoryID = category.id
        updated.categoryName = category.name
        updated.categoryIcon = category.icon
        updated.isFixed = isFixed
        store.updateExpense(updated)
        dismiss()
    }
}
