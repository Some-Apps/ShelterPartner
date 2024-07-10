//
//  ReasonsForEarlyPutBackView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/7/24.
//

import SwiftUI

struct ReasonsForEarlyPutBackView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    @State private var newReason = ""
    
    var body: some View {
        Form {
            Section {
                TextField("New Reason", text: $newReason)
                
                if newReason.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Button("Add Reason") {
                        viewModel.addReason(reason: newReason)
                        newReason = ""
                    }
                    .disabled(newReason.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                }
            }
            if (!authViewModel.earlyReasons.isEmpty) {
                Section("Reasons") {
                    ForEach(authViewModel.earlyReasons, id: \.self) { reason in
                        HStack {
                            Text(reason)
                                .font(.title3)
                        }
                    }
                    .onMove(perform: moveReason)
                    .onDelete(perform: deleteReason)
                }
            }
        }
        .navigationTitle("Early Put Back Reasons")
        .toolbar {
            EditButton()
        }

    }
    private func moveReason(from source: IndexSet, to destination: Int) {
        viewModel.moveReason(from: source, to: destination)
    }

    private func deleteReason(at offsets: IndexSet) {
        viewModel.deleteReason(at: offsets)
    }
}
