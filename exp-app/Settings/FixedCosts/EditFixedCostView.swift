//
//  EditFixedCostView.swift
//  exp-app
//

import SwiftUI

struct EditFixedCostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    let template: FixedCostTemplate
    
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: CustomCategory?
    @FocusState private var amountFieldFocused: Bool
    
    init(template: FixedCostTemplate) {
        self.template = template
        _title = State(initialValue: template.title)
        _amount = State(initialValue: ExpenseStore.formatAmountForInput(template.amount))
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
            .navigationTitle("Edit Fixed Cost")
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
                if selectedCategory == nil {
                    selectedCategory = store.categories.first(where: { $0.id == template.categoryID })
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
        
        var updated = template
        updated.title = title
        updated.amount = value
        updated.categoryID = category.id
        updated.categoryName = category.name
        updated.categoryIcon = category.icon
        store.updateFixedCostTemplate(updated)
        dismiss()
    }
}
