//
//  DashboardCustomizeView.swift
//  exp-app
//

import SwiftUI

struct DashboardCustomizeView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var configs: [DashboardWidgetConfig] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(configs.enumerated()), id: \.element.id) { index, config in
                        HStack {
                            Image(systemName: config.widget.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            Text(config.widget.displayName)
                            Spacer()
                            Toggle("", isOn: $configs[index].isEnabled)
                                .labelsHidden()
                        }
                    }
                    .onMove { from, to in
                        configs.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Drag to reorder, toggle to show/hide")
                } footer: {
                    Text("Month selector and budget summary always appear at the top.")
                }
                
                Section {
                    Button("Reset to Default") {
                        configs = ExpenseStore.defaultWidgetConfig()
                    }
                }
            }
#if os(iOS)
            .environment(\.editMode, .constant(.active))
#endif
            .navigationTitle("Customize Dashboard")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.dashboardWidgets = configs
                        dismiss()
                    }
                }
            }
            .onAppear {
                configs = store.dashboardWidgets
                // Ensure any new widgets added in updates are present
                let existing = Set(configs.map(\.widget))
                for widget in DashboardWidget.allCases where !existing.contains(widget) {
                    configs.append(DashboardWidgetConfig(widget: widget, isEnabled: false))
                }
            }
        }
    }
}
