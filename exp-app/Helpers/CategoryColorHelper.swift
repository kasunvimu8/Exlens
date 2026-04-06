import SwiftUI

extension ExpenseStore {
    func colorForCategory(_ categoryID: UUID) -> Color {
        if let category = categories.first(where: { $0.id == categoryID }) {
            return Color.fromString(category.color)
        }
        let palette: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .cyan, .brown, .indigo, .teal]
        return palette[abs(categoryID.hashValue) % palette.count]
    }
}
