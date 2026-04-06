import SwiftUI

struct CategoriesView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showingAddCategory = false
    @State private var editingCategory: CustomCategory?
    
    var body: some View {
        List {
            ForEach(store.categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.body)
                            .foregroundStyle(Color.fromString(category.color))
                            .frame(width: 34, height: 34)
                            .background(Color.fromString(category.color).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        
                        Text(category.name)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                store.deleteCategory(at: offsets)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
        .overlay {
            if store.categories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "folder",
                    description: Text("Tap + to add your first category.")
                )
            }
        }
    }
}
