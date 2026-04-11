//
//  FixedCostsView.swift
//  exp-app
//

import SwiftUI

struct FixedCostsView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showingAdd = false
    @State private var templateToEdit: FixedCostTemplate?
    
    var body: some View {
        List {
            if store.fixedCostTemplates.isEmpty {
                ContentUnavailableView(
                    "No Fixed Costs",
                    systemImage: "pin.slash",
                    description: Text("Add recurring expenses like rent, subscriptions, or insurance. Apply them all at once each month.")
                )
            } else {
                Section {
                    ForEach(store.fixedCostTemplates) { template in
                        templateRow(template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                templateToEdit = template
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.deleteFixedCostTemplate(id: template.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    templateToEdit = template
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                    }
                } footer: {
                    let total = store.fixedCostTemplates.reduce(0) { $0 + $1.amount }
                    Text("Total: \(total.formatted(.currency(code: store.selectedCurrency))) per month")
                }
            }
        }
        .navigationTitle("Fixed Costs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddFixedCostView()
        }
        .sheet(item: $templateToEdit) { template in
            EditFixedCostView(template: template)
        }
    }
    
    private func templateRow(_ template: FixedCostTemplate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: template.categoryIcon)
                .font(.body)
                .foregroundStyle(store.colorForCategory(template.categoryID))
                .frame(width: 36, height: 36)
                .background(store.colorForCategory(template.categoryID).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(template.title)
                    .font(.body)
                Text(template.categoryName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(template.amount, format: .currency(code: store.selectedCurrency))
                .font(.body.monospacedDigit())
        }
    }
}
