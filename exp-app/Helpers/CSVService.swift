//
//  CSVService.swift
//  exp-app
//

import Foundation

struct CSVRowError: Identifiable {
    let id = UUID()
    let row: Int
    let column: String
    let message: String
}

struct ParsedExpenseRow: Identifiable {
    let id = UUID()
    let description: String
    let category: String
    let date: Date
    let amount: Double
    let isFixed: Bool
    let sourceRow: Int
}

struct CSVParseResult {
    let expenses: [ParsedExpenseRow]
    let errors: [CSVRowError]
    var isValid: Bool { errors.isEmpty }
}

enum CSVService {
    
    static let expectedHeaders = ["description", "category", "date", "amount", "isfixed"]
    
    // MARK: - Parse
    
    static func parse(csvString: String) -> CSVParseResult {
        var expenses: [ParsedExpenseRow] = []
        var errors: [CSVRowError] = []
        
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard lines.count >= 2 else {
            errors.append(CSVRowError(row: 0, column: "-", message: "File is empty or has no data rows."))
            return CSVParseResult(expenses: [], errors: errors)
        }
        
        // Auto-detect delimiter: tab vs comma
        let delimiter = detectDelimiter(lines[0])
        
        // Validate header
        let headerFields = parseLine(lines[0], delimiter: delimiter).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        let missingColumns = Set(expectedHeaders).subtracting(headerFields)
        if !missingColumns.isEmpty {
            errors.append(CSVRowError(
                row: 0, column: "header",
                message: "Missing columns: \(missingColumns.sorted().joined(separator: ", ")). Expected: description, category, date, amount, isFixed"
            ))
            return CSVParseResult(expenses: [], errors: errors)
        }
        
        // Build column index map
        let columnIndex: [String: Int] = Dictionary(
            uniqueKeysWithValues: headerFields.enumerated().map { ($1, $0) }
        )
        
        // Date formatters
        let dateFormatters: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy/MM/dd", "dd.MM.yyyy",
                "M/d/yy", "M/dd/yy", "MM/d/yy", "d/M/yy", "dd/MM/yy",
                "M/d/yyyy", "d.M.yyyy", "d-M-yyyy"
            ]
            return formats.map { fmt in
                let df = DateFormatter()
                df.dateFormat = fmt
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }
        }()
        
        // Parse data rows
        for lineIndex in 1..<lines.count {
            let rowNumber = lineIndex
            let fields = parseLine(lines[lineIndex], delimiter: delimiter)
            
            guard fields.count >= expectedHeaders.count else {
                errors.append(CSVRowError(
                    row: rowNumber, column: "-",
                    message: "Row has \(fields.count) columns, expected \(expectedHeaders.count)."
                ))
                continue
            }
            
            let desc = fields[columnIndex["description"]!].trimmingCharacters(in: .whitespaces)
            let cat = fields[columnIndex["category"]!].trimmingCharacters(in: .whitespaces)
            let dateStr = fields[columnIndex["date"]!].trimmingCharacters(in: .whitespaces)
            let amountStr = fields[columnIndex["amount"]!].trimmingCharacters(in: .whitespaces)
            let isFixedStr = fields[columnIndex["isfixed"]!].trimmingCharacters(in: .whitespaces).lowercased()
            
            if desc.isEmpty {
                errors.append(CSVRowError(row: rowNumber, column: "description", message: "Description is empty."))
                continue
            }
            
            if cat.isEmpty {
                errors.append(CSVRowError(row: rowNumber, column: "category", message: "Category is empty."))
                continue
            }
            
            // Parse date with multiple format attempts
            var parsedDate: Date?
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateStr) {
                    parsedDate = date
                    break
                }
            }
            guard let date = parsedDate else {
                errors.append(CSVRowError(row: rowNumber, column: "date", message: "Invalid date '\(dateStr)'. Expected format: yyyy-MM-dd."))
                continue
            }
            
            // Parse amount (accept both , and . as decimal separator)
            let normalizedAmount = amountStr.replacingOccurrences(of: ",", with: ".")
            guard let amount = Double(normalizedAmount), amount >= 0 else {
                errors.append(CSVRowError(row: rowNumber, column: "amount", message: "Invalid amount '\(amountStr)'. Must be a valid number."))
                continue
            }
            
            // Parse isFixed
            let isFixed: Bool
            switch isFixedStr {
            case "true", "yes", "1": isFixed = true
            case "false", "no", "0", "": isFixed = false
            default:
                errors.append(CSVRowError(row: rowNumber, column: "isFixed", message: "Invalid isFixed value '\(isFixedStr)'. Expected true/false, yes/no, or 1/0."))
                continue
            }
            
            expenses.append(ParsedExpenseRow(
                description: desc, category: cat, date: date,
                amount: amount, isFixed: isFixed, sourceRow: rowNumber
            ))
        }
        
        return CSVParseResult(expenses: expenses, errors: errors)
    }
    
    // MARK: - Delimiter Detection
    
    static func detectDelimiter(_ headerLine: String) -> Character {
        let tabCount = headerLine.filter { $0 == "\t" }.count
        let commaCount = headerLine.filter { $0 == "," }.count
        let semicolonCount = headerLine.filter { $0 == ";" }.count
        
        // Pick the delimiter that produces the most splits (closest to 5 columns)
        if tabCount >= 4 { return "\t" }
        if semicolonCount > commaCount && semicolonCount >= 4 { return ";" }
        return ","
    }
    
    // MARK: - Line Parser (handles quoted fields, configurable delimiter)
    
    static func parseLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        
        let chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                if inQuotes {
                    // Check if next char is also a quote (escaped quote)
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 2
                        continue
                    } else {
                        // Closing quote
                        inQuotes = false
                    }
                } else {
                    // Opening quote
                    inQuotes = true
                }
            } else if char == delimiter && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
            
            i += 1
        }
        fields.append(current)
        return fields
    }
    
    // MARK: - Export
    
    static func exportCSV(expenses: [Expense]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        var csv = "description,category,date,amount,isFixed\n"
        
        for expense in expenses.sorted(by: { $0.date < $1.date }) {
            let desc = escapeCSVField(expense.title)
            let cat = escapeCSVField(expense.categoryName)
            let date = dateFormatter.string(from: expense.date)
            let amount = String(format: "%.2f", expense.amount)
            let isFixed = expense.isFixed ? "true" : "false"
            
            csv += "\(desc),\(cat),\(date),\(amount),\(isFixed)\n"
        }
        
        return csv
    }
    
    static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
