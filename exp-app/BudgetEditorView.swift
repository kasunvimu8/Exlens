//
//  BudgetEditorView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import SwiftUI

struct BudgetEditorView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let year: Int
    let month: Int
    let currentAmount: Double
    
    @State private var budgetText = ""
    @FocusState private var isFocused: Bool
    
    private var monthLabel: String {
        let components = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.wide).year())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField(ExpenseStore.amountPlaceholder, text: $budgetText)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .focused($isFocused)
                            .onChange(of: budgetText) { oldValue, newValue in
                                budgetText = ExpenseStore.sanitizeDecimalInput(old: oldValue, new: newValue)
                            }
                    }
                } header: {
                    Text("Budget for \(monthLabel)")
                } footer: {
                    Text("Enter the total amount you plan to spend this month.")
                }
                
                if currentAmount > 0 {
                    Section {
                        Button("Remove Budget", role: .destructive) {
                            store.removeBudget(year: year, month: month)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Monthly Budget")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = ExpenseStore.parseAmount(budgetText), value > 0 {
                            store.setBudget(amount: value, year: year, month: month)
                        }
                        dismiss()
                    }
                    .disabled(ExpenseStore.parseAmount(budgetText) == nil || (ExpenseStore.parseAmount(budgetText) ?? 0) <= 0)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { isFocused = false }
                    }
                }
            }
            .onAppear {
                if currentAmount > 0 {
                    budgetText = ExpenseStore.formatAmountForInput(currentAmount)
                } else if store.defaultBudget > 0 {
                    budgetText = ExpenseStore.formatAmountForInput(store.defaultBudget)
                }
                isFocused = true
            }
        }
    }
    
    private var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [
            NSLocale.Key.currencyCode.rawValue: store.selectedCurrency
        ]))
        return locale.currencySymbol ?? store.selectedCurrency
    }
}
