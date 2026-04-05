//
//  SettingsView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showingAddCategory = false
    @State private var editingCategory: CustomCategory?
    @State private var defaultBudgetText = ""
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
                    ForEach(store.categories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.body)
                                .foregroundStyle(Color.fromString(category.color))
                                .frame(width: 34, height: 34)
                                .background(Color.fromString(category.color).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            
                            Text(category.name)
                            
                            Spacer()
                            
                            Button {
                                editingCategory = category
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        store.deleteCategory(at: offsets)
                    }
                } header: {
                    Label("Categories", systemImage: "folder.fill")
                } footer: {
                    Text("Swipe to delete categories. Note: Deleting a category won't delete existing expenses.")
                }
                
                Section {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
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
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField(ExpenseStore.amountPlaceholder, text: $defaultBudgetText)
                            .keyboardType(.decimalPad)
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
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $editingCategory) { category in
                EditCategoryView(category: category)
            }
            .sheet(isPresented: $showingImport) {
                CSVImportView()
            }
            .sheet(isPresented: $showingExport) {
                CSVExportShareSheet(fileURL: generateExportURL())
            }
            .alert("Delete All Expenses", isPresented: $showingDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    store.deleteAllExpenses()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(store.expenses.count) expenses. This action cannot be undone.")
            }
            .onAppear {
                if store.defaultBudget > 0 {
                    defaultBudgetText = ExpenseStore.formatAmountForInput(store.defaultBudget)
                }
            }
        }
    }
    
    private var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [
            NSLocale.Key.currencyCode.rawValue: store.selectedCurrency
        ]))
        return locale.currencySymbol ?? store.selectedCurrency
    }
    
    private func generateExportURL() -> URL {
        let csvString = CSVService.exportCSV(expenses: store.expenses)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Exlens_Expenses.csv")
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

struct CSVExportShareSheet: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                
                Text("CSV Ready to Share")
                    .font(.title3.bold())
                
                Text("Your expenses have been exported to a CSV file.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                ShareLink(
                    item: fileURL,
                    preview: SharePreview("Exlens_Expenses.csv", icon: Image(systemName: "doc.text"))
                ) {
                    Label("Share CSV File", systemImage: "square.and.arrow.up")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    @State private var name = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = "blue"
    
    let availableIcons = [
        "tag.fill", "fork.knife", "car.fill", "bag.fill", "doc.text.fill",
        "film.fill", "house.fill", "heart.fill", "gamecontroller.fill",
        "book.fill", "cart.fill", "creditcard.fill", "gift.fill",
        "cup.and.saucer.fill", "bandage.fill", "bicycle", "airplane",
        "tshirt.fill", "phone.fill", "desktopcomputer", "paintbrush.fill"
    ]
    
    let availableColors = [
        "red", "orange", "yellow", "green", "blue", "purple",
        "pink", "gray", "brown", "cyan", "indigo", "mint", "teal"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? Color.accentColor : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.accentColor.opacity(0.1) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorName in
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(Color.fromString(colorName))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColor == colorName ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(Color.fromString(selectedColor))
                                .frame(width: 64, height: 64)
                                .background(Color.fromString(selectedColor).opacity(0.12), in: Circle())
                            Text(name.isEmpty ? "Preview" : name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let category = CustomCategory(
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        store.addCategory(category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    var category: CustomCategory
    
    @State private var name = ""
    @State private var selectedIcon = ""
    @State private var selectedColor = ""
    @State private var showingDeleteConfirmation = false
    
    let availableIcons = [
        "tag.fill", "fork.knife", "car.fill", "bag.fill", "doc.text.fill",
        "film.fill", "house.fill", "heart.fill", "gamecontroller.fill",
        "book.fill", "cart.fill", "creditcard.fill", "gift.fill",
        "cup.and.saucer.fill", "bandage.fill", "bicycle", "airplane",
        "tshirt.fill", "phone.fill", "desktopcomputer", "paintbrush.fill"
    ]
    
    let availableColors = [
        "red", "orange", "yellow", "green", "blue", "purple",
        "pink", "gray", "brown", "cyan", "indigo", "mint", "teal"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? Color.accentColor : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.accentColor.opacity(0.1) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorName in
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(Color.fromString(colorName))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColor == colorName ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(Color.fromString(selectedColor))
                                .frame(width: 64, height: 64)
                                .background(Color.fromString(selectedColor).opacity(0.12), in: Circle())
                            Text(name.isEmpty ? "Preview" : name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
                
                Section {
                    Button("Delete Category", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = category
                        updated.name = name
                        updated.icon = selectedIcon
                        updated.color = selectedColor
                        store.updateCategory(updated)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let index = store.categories.firstIndex(where: { $0.id == category.id }) {
                        store.categories.remove(at: index)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure? Existing expenses with this category won't be deleted.")
            }
            .onAppear {
                name = category.name
                selectedIcon = category.icon
                selectedColor = category.color
            }
        }
    }
}
