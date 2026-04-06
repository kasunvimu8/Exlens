import SwiftUI
import Charts

struct CategoryComparisonBarWidget: View {
    @Environment(ExpenseStore.self) private var store
    let selectedDate: Date
    let currencyCode: String
    @Binding var selectedBarCategory: String?
    
    private var calendar: Calendar { Calendar.current }
    
    private struct CategoryMonthData: Identifiable {
        let id = UUID()
        let categoryName: String
        let monthLabel: String
        let amount: Double
    }
    
    var body: some View {
        let prevDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        let prevYear = calendar.component(.year, from: prevDate)
        let prevMonth = calendar.component(.month, from: prevDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        let selectedMonth = calendar.component(.month, from: selectedDate)
        
        let currentBreakdown = store.categoryBreakdown(for: selectedYear, month: selectedMonth)
        let previousBreakdown = store.categoryBreakdown(for: prevYear, month: prevMonth)
        
        let currentLabel = selectedDate.formatted(.dateTime.month(.abbreviated))
        let previousLabel = prevDate.formatted(.dateTime.month(.abbreviated))
        
        var allCategories: [(name: String, categoryID: UUID)] = []
        var seen = Set<UUID>()
        for item in currentBreakdown + previousBreakdown {
            if seen.insert(item.categoryID).inserted {
                allCategories.append((name: item.name, categoryID: item.categoryID))
            }
        }
        
        let currentMap = Dictionary(uniqueKeysWithValues: currentBreakdown.map { ($0.categoryID, $0.total) })
        let previousMap = Dictionary(uniqueKeysWithValues: previousBreakdown.map { ($0.categoryID, $0.total) })
        
        var chartData: [CategoryMonthData] = []
        for cat in allCategories {
            if let val = previousMap[cat.categoryID], val > 0 {
                chartData.append(CategoryMonthData(categoryName: cat.name, monthLabel: previousLabel, amount: val))
            }
            if let val = currentMap[cat.categoryID], val > 0 {
                chartData.append(CategoryMonthData(categoryName: cat.name, monthLabel: currentLabel, amount: val))
            }
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Category Comparison")
                .font(.headline)
            
            Text("\(previousLabel) vs \(currentLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if chartData.isEmpty {
                Text("No data to compare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Category", item.categoryName),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(by: .value("Month", item.monthLabel))
                    .position(by: .value("Month", item.monthLabel))
                    .cornerRadius(4)
                    .opacity(selectedBarCategory == nil || selectedBarCategory == item.categoryName ? 1.0 : 0.4)
                }
                .chartXSelection(value: $selectedBarCategory)
                .chartForegroundStyleScale([
                    previousLabel: Color.accentColor.opacity(0.5),
                    currentLabel: Color.accentColor
                ])
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: currencyCode))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                
                if let selected = selectedBarCategory {
                    let currentAmt = chartData.first(where: { $0.categoryName == selected && $0.monthLabel == currentLabel })?.amount
                    let previousAmt = chartData.first(where: { $0.categoryName == selected && $0.monthLabel == previousLabel })?.amount
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selected)
                            .font(.caption.bold())
                        HStack(spacing: 16) {
                            if let prev = previousAmt {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.accentColor.opacity(0.5)).frame(width: 8, height: 8)
                                    Text("\(previousLabel): \(prev, format: .currency(code: currencyCode))")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if let curr = currentAmt {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                                    Text("\(currentLabel): \(curr, format: .currency(code: currencyCode))")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
