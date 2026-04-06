import SwiftUI

struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerMonth: Int
    @State private var pickerYear: Int
    
    private let months = Calendar.current.monthSymbols
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    
    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let cal = Calendar.current
        _pickerMonth = State(initialValue: cal.component(.month, from: selectedDate.wrappedValue))
        _pickerYear = State(initialValue: cal.component(.year, from: selectedDate.wrappedValue))
    }
    
    private var yearRange: [Int] {
        Array((currentYear - 10)...currentYear)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("Month", selection: $pickerMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(months[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Year", selection: $pickerYear) {
                        ForEach(yearRange, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)
                
                Button {
                    if let date = Calendar.current.date(from: DateComponents(year: pickerYear, month: pickerMonth, day: 1)) {
                        if date <= Date() {
                            selectedDate = date
                        }
                    }
                    dismiss()
                } label: {
                    Text("Select")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
