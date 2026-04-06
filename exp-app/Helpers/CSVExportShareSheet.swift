import SwiftUI

struct CSVExportShareSheet: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                
                Text("CSV Ready to Share")
                    .font(.title3.bold())
                
                Text("Your expenses have been exported to a CSV file.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                ShareLink(
                    item: fileURL,
                    preview: SharePreview("Exlens_Expenses.csv", icon: Image(systemName: "doc.text"))
                ) {
                    Label("Share CSV File", systemImage: "square.and.arrow.up")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Export")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
