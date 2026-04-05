//
//  CSVImportView.swift
//  exp-app
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    enum ImportStep {
        case pickFile
        case showErrors(errors: [CSVRowError])
        case resolveCategories(result: CSVParseResult, unmatched: [String])
        case preview(result: CSVParseResult, categoryMap: [String: CustomCategory])
        case done(count: Int)
    }
    
    @State private var importStep: ImportStep = .pickFile
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch importStep {
                case .pickFile:
                    filePickerPrompt
                case .showErrors(let errors):
                    errorListView(errors)
                case .resolveCategories(let result, let unmatched):
                    categoryResolutionView(result: result, unmatched: unmatched)
                case .preview(let result, let categoryMap):
                    previewView(result: result, categoryMap: categoryMap)
                case .done(let count):
                    importSuccessView(count: count)
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                onCompletion: handleFileSelection
            )
        }
    }
    
    // MARK: - Step 1: File Picker Prompt
    
    private var filePickerPrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            
            Text("Import Expenses from CSV")
                .font(.title3.bold())
            
            VStack(spacing: 8) {
                Text("Select a CSV file with these columns:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("description, category, date, amount, isFixed")
                    .font(.subheadline.monospaced())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                
                Text("Date format: yyyy-MM-dd (e.g. 2025-03-15)\nisFixed: true/false or yes/no")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingFilePicker = true
            } label: {
                Label("Choose CSV File", systemImage: "folder")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Step 2: Error List
    
    private func errorListView(_ errors: [CSVRowError]) -> some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Validation Failed")
                            .font(.headline)
                        Text("Please fix the errors in your CSV file and try again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Errors (\(errors.count))") {
                ForEach(errors) { error in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if error.row > 0 {
                                Text("Row \(error.row)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red, in: Capsule())
                            }
                            if error.column != "-" {
                                Text(error.column)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill), in: Capsule())
                            }
                        }
                        Text(error.message)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Choose Different File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Step 3: Category Resolution
    
    private func categoryResolutionView(result: CSVParseResult, unmatched: [String]) -> some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("New Categories Found")
                            .font(.headline)
                        Text("These categories from your CSV don't exist yet. They will be created with a default icon and gray color.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Will Be Created (\(unmatched.count))") {
                ForEach(unmatched, id: \.self) { name in
                    HStack(spacing: 12) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        
                        Text(name)
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            Section {
                Button {
                    let categoryMap = createCategoriesAndBuildMap(
                        result: result,
                        unmatchedToCreate: Set(unmatched)
                    )
                    importStep = .preview(result: result, categoryMap: categoryMap)
                } label: {
                    Text("Create Categories & Continue")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Step 4: Preview
    
    private func previewView(result: CSVParseResult, categoryMap: [String: CustomCategory]) -> some View {
        List {
            Section("Import Summary") {
                HStack {
                    Label("Total Expenses", systemImage: "number")
                    Spacer()
                    Text("\(result.expenses.count)")
                        .font(.body.bold().monospacedDigit())
                }
                
                let total = result.expenses.reduce(0) { $0 + $1.amount }
                HStack {
                    Label("Total Amount", systemImage: "banknote")
                    Spacer()
                    Text(total, format: .currency(code: store.selectedCurrency))
                        .font(.body.monospacedDigit())
                }
                
                if let earliest = result.expenses.map(\.date).min(),
                   let latest = result.expenses.map(\.date).max() {
                    HStack {
                        Label("Date Range", systemImage: "calendar")
                        Spacer()
                        Text("\(earliest.formatted(date: .abbreviated, time: .omitted)) – \(latest.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                    }
                }
                
                let categories = Set(result.expenses.map(\.category))
                HStack {
                    Label("Categories", systemImage: "folder")
                    Spacer()
                    Text("\(categories.count)")
                        .font(.body.monospacedDigit())
                }
                
                let fixedCount = result.expenses.filter(\.isFixed).count
                HStack {
                    Label("Fixed / Variable", systemImage: "pin")
                    Spacer()
                    Text("\(fixedCount) / \(result.expenses.count - fixedCount)")
                        .font(.body.monospacedDigit())
                }
            }
            
            Section("Preview (first 10 rows)") {
                ForEach(result.expenses.prefix(10)) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.description)
                                .font(.body)
                            Spacer()
                            Text(row.amount, format: .currency(code: store.selectedCurrency))
                                .font(.body.monospacedDigit())
                        }
                        HStack(spacing: 4) {
                            Text(row.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\u{2022}")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(row.date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if row.isFixed {
                                Text("Fixed")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor, in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                if result.expenses.count > 10 {
                    Text("... and \(result.expenses.count - 10) more")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Section {
                Button {
                    performImport(result: result, categoryMap: categoryMap)
                } label: {
                    Label("Import \(result.expenses.count) Expenses", systemImage: "square.and.arrow.down")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Step 5: Success
    
    private func importSuccessView(count: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
            
            Text("Import Complete!")
                .font(.title3.bold())
            
            Text("\(count) expenses imported successfully.")
                .foregroundStyle(.secondary)
            
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Logic
    
    private func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            processFile(url)
        case .failure:
            break
        }
    }
    
    private func processFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importStep = .showErrors(errors: [
                CSVRowError(row: 0, column: "-", message: "Could not access the selected file. Please try again.")
            ])
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let data = try? Data(contentsOf: url),
              let csvString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            importStep = .showErrors(errors: [
                CSVRowError(row: 0, column: "-", message: "Could not read the file. Make sure it is a valid text file.")
            ])
            return
        }
        
        let parseResult = CSVService.parse(csvString: csvString)
        
        if !parseResult.errors.isEmpty {
            importStep = .showErrors(errors: parseResult.errors)
            return
        }
        
        if parseResult.expenses.isEmpty {
            importStep = .showErrors(errors: [
                CSVRowError(row: 0, column: "-", message: "No valid expense rows found in the file.")
            ])
            return
        }
        
        // Check for unmatched categories
        let existingNames = Set(store.categories.map { $0.name.lowercased() })
        let csvCategories = Set(parseResult.expenses.map { $0.category })
        let unmatched = csvCategories.filter { !existingNames.contains($0.lowercased()) }
        
        if !unmatched.isEmpty {
            importStep = .resolveCategories(
                result: parseResult,
                unmatched: unmatched.sorted()
            )
        } else {
            let categoryMap = buildExistingCategoryMap()
            importStep = .preview(result: parseResult, categoryMap: categoryMap)
        }
    }
    
    private func buildExistingCategoryMap() -> [String: CustomCategory] {
        var map: [String: CustomCategory] = [:]
        for category in store.categories {
            map[category.name.lowercased()] = category
        }
        return map
    }
    
    private func createCategoriesAndBuildMap(
        result: CSVParseResult,
        unmatchedToCreate: Set<String>
    ) -> [String: CustomCategory] {
        var map = buildExistingCategoryMap()
        
        for name in unmatchedToCreate {
            let newCategory = CustomCategory(
                name: name,
                icon: "ellipsis.circle.fill",
                color: "gray"
            )
            store.addCategory(newCategory)
            map[name.lowercased()] = newCategory
        }
        
        return map
    }
    
    private func performImport(
        result: CSVParseResult,
        categoryMap: [String: CustomCategory]
    ) {
        var newExpenses: [Expense] = []
        
        for row in result.expenses {
            if let category = categoryMap[row.category.lowercased()] {
                newExpenses.append(Expense(
                    title: row.description,
                    amount: row.amount,
                    date: row.date,
                    categoryID: category.id,
                    categoryName: category.name,
                    categoryIcon: category.icon,
                    isFixed: row.isFixed
                ))
            }
        }
        
        store.importExpenses(newExpenses)
        importStep = .done(count: newExpenses.count)
    }
}
