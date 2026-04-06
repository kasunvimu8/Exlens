import SwiftUI

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    var category: CustomCategory
    
    @State private var name = ""
    @State private var selectedIcon = ""
    @State private var selectedColor = ""
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: selectedIcon.isEmpty ? "tag.fill" : selectedIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(Color.fromString(selectedColor.isEmpty ? "blue" : selectedColor))
                                .frame(width: 64, height: 64)
                                .background(Color.fromString(selectedColor.isEmpty ? "blue" : selectedColor).opacity(0.12), in: Circle())
                            Text(name.isEmpty ? "Preview" : name)
                                .font(.subheadline.bold())
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                
                Section("Name") {
                    TextField("Category name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(categoryIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(selectedIcon == icon ? Color.accentColor : .secondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.accentColor.opacity(0.12) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(categoryColors, id: \.self) { colorName in
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(Color.fromString(colorName))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColor == colorName ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button("Delete Category", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Category")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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
