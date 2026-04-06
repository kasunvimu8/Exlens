import Foundation

enum ExportHelper {
    static func generateExportURL(expenses: [Expense]) -> URL {
        let csvString = CSVService.exportCSV(expenses: expenses)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Exlens_Expenses.csv")
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
