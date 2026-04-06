import SwiftUI

struct CategoryBreakdownWidget: View {
    @Environment(ExpenseStore.self) private var store
    let breakdown: [(name: String, icon: String, categoryID: UUID, total: Double)]
    let totalSpent: Double
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Details")
                .font(.headline)
            
            ForEach(breakdown, id: \.categoryID) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.body)
                        .foregroundStyle(store.colorForCategory(item.categoryID))
                        .frame(width: 34, height: 34)
                        .background(store.colorForCategory(item.categoryID).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                        if totalSpent > 0 {
                            Text("\(Int(item.total / totalSpent * 100))% of total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.total, format: .currency(code: currencyCode))
                        .font(.body.monospacedDigit())
                }
                
                if item.categoryID != breakdown.last?.categoryID {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
