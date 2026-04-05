//
//  AddExpenseView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 04.04.26.
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store

    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: CustomCategory?
    @State private var isFixed = false
    @FocusState private var amountFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField(ExpenseStore.amountPlaceholder, text: $amount)
                            .keyboardType(.decimalPad)
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
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
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
                // Select first category by default
                if selectedCategory == nil, let first = store.categories.first {
                    selectedCategory = first
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
    
    private var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: store.selectedCurrency]))
        return locale.currencySymbol ?? store.selectedCurrency
    }
    
    private func saveExpense() {
        guard let value = ExpenseStore.parseAmount(amount),
              let category = selectedCategory else { return }
        
        let expense = Expense(
            title: title,
            amount: value,
            date: date,
            categoryID: category.id,
            categoryName: category.name,
            categoryIcon: category.icon,
            isFixed: isFixed
        )
        store.add(expense)
        dismiss()
    }
}
