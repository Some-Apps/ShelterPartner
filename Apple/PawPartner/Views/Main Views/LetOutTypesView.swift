import SwiftUI

struct LetOutTypesView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    @State private var newType = ""
    
    var body: some View {
        Form {
            Section {
                TextField("New Let Out Type", text: $newType)
                
                if newType.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Button("Add Let Out Type") {
                        viewModel.addItem(title: newType, category: "letOutTypes")
                        newType = ""
                    }
                    .disabled(newType.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                }
            }
            if (!authViewModel.earlyReasons.isEmpty) {
                Section("Let Out Types") {
                    ForEach(authViewModel.letOutTypes, id: \.self) { type in
                        HStack {
                            Text(type)
                                .font(.title3)
                        }
                    }
                    .onMove(perform: moveItem)
                    .onDelete(perform: deleteItem)
                }
            }
        }
        .navigationTitle("Let Out Types")
        .toolbar {
            EditButton()
        }

    }
    private func moveItem(from source: IndexSet, to destination: Int) {
        viewModel.moveItem(from: source, to: destination)
    }

    private func deleteItem(at offsets: IndexSet) {
        viewModel.deleteItem(at: offsets)
    }
}
