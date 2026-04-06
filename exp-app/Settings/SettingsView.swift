import SwiftUI

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var defaultBudgetText = ""
    @FocusState private var budgetFieldFocused: Bool
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var showingDeleteAllConfirmation = false
    
    private let availableCurrencies: [(code: String, symbol: String)] = [
        ("EUR", "€"), ("USD", "$"), ("GBP", "£"), ("JPY", "¥"),
        ("CHF", "CHF"), ("CAD", "CA$"), ("AUD", "A$"), ("CNY", "¥"),
        ("INR", "₹"), ("KRW", "₩"), ("SEK", "kr"), ("NOK", "kr"),
        ("DKK", "kr"), ("PLN", "zł"), ("CZK", "Kč"), ("HUF", "Ft"),
        ("TRY", "₺"), ("BRL", "R$"), ("MXN", "MX$"), ("SGD", "S$")
    ]
    
    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        HStack {
                            Label("Categories", systemImage: "folder.fill")
                            Spacer()
                            Text("\(store.categories.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Picker("Currency", selection: $store.selectedCurrency) {
                        ForEach(availableCurrencies, id: \.code) { currency in
                            Text("\(currency.code) (\(currency.symbol))")
                                .tag(currency.code)
                        }
                    }
                } header: {
                    Label("Currency", systemImage: "dollarsign.circle.fill")
                } footer: {
                    Text("Select the currency used for displaying expenses.")
                }
                
                Section {
                    HStack {
                        Text(store.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField(ExpenseStore.amountPlaceholder, text: $defaultBudgetText)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .focused($budgetFieldFocused)
                            .onChange(of: defaultBudgetText) { oldValue, newValue in
                                let sanitized = ExpenseStore.sanitizeDecimalInput(old: oldValue, new: newValue)
                                if sanitized != newValue {
                                    defaultBudgetText = sanitized
                                }
                                if let value = ExpenseStore.parseAmount(sanitized), value > 0 {
                                    store.defaultBudget = value
                                } else if sanitized.isEmpty {
                                    store.defaultBudget = 0
                                }
                            }
                    }
                } header: {
                    Label("Default Budget", systemImage: "target")
                } footer: {
                    Text("Pre-fills the budget amount when setting a new monthly budget. Set to 0 to disable.")
                }
                
                Section {
                    Picker("Appearance", selection: $store.appTheme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                } footer: {
                    Text("Choose light, dark, or follow system settings.")
                }
                
                Section {
                    Button {
                        showingImport = true
                    } label: {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        showingExport = true
                    } label: {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.expenses.isEmpty)
                } header: {
                    Label("Data", systemImage: "externaldrive.fill")
                } footer: {
                    Text("Import expenses from a CSV file or export all expenses. CSV columns: description, category, date, amount, isFixed.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Expenses", systemImage: "trash")
                    }
                    .disabled(store.expenses.isEmpty)
                } header: {
                    Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingImport) {
                CSVImportView()
            }
            .sheet(isPresented: $showingExport) {
                CSVExportShareSheet(fileURL: ExportHelper.generateExportURL(expenses: store.expenses))
            }
            .alert("Delete All Expenses", isPresented: $showingDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    store.deleteAllExpenses()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(store.expenses.count) expenses. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { budgetFieldFocused = false }
                }
            }
            .onAppear {
                if store.defaultBudget > 0 {
                    defaultBudgetText = ExpenseStore.formatAmountForInput(store.defaultBudget)
                }
            }
        }
    }
}
