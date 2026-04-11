//
//  AddFixedCostView.swift
//  exp-app
//

import SwiftUI

struct AddFixedCostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: CustomCategory?
    @FocusState private var amountFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g. Rent, Netflix)", text: $title)
                    
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
            .navigationTitle("Add Fixed Cost")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { amountFieldFocused = false }
                    }
                }
            }
            .onAppear {
                if selectedCategory == nil, let first = store.categories.first {
                    selectedCategory = first
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard !title.isEmpty,
              let value = ExpenseStore.parseAmount(amount),
              value > 0,
              selectedCategory != nil else { return false }
        return true
    }
    
    private func save() {
        guard let value = ExpenseStore.parseAmount(amount),
              let category = selectedCategory else { return }
        
        let template = FixedCostTemplate(
            title: title,
            amount: value,
            categoryID: category.id,
            categoryName: category.name,
            categoryIcon: category.icon
        )
        store.addFixedCostTemplate(template)
        dismiss()
    }
}
