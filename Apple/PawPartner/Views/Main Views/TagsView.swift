//
//  TagsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/21/23.
//

import SwiftUI

struct TagsView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    let species: AnimalType
    @State private var newTag = ""

    var body: some View {
        Form {
            Section {
                TextField("New Tag", text: $newTag)
                
                if newTag.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Button("Add Tag") {
                        viewModel.addTag(tag: newTag, species: species)
                        newTag = ""
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                }
                
            }
            if (species == .Cat ? !viewModel.catTags.isEmpty : !viewModel.dogTags.isEmpty) {
                Section("Tags") {
                    ForEach(species == .Cat ? viewModel.catTags : viewModel.dogTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.title3)
                        }
                    }
                    .onMove(perform: moveTag)
                    .onDelete(perform: deleteTag)
                }
            }
        }
        .navigationTitle(species == .Cat ? "Cat Tags" : "Dog Tags")
        .toolbar {
            EditButton()
        }
    }
    private func moveTag(from source: IndexSet, to destination: Int) {
        viewModel.moveTag(from: source, to: destination, species: species)
    }

    private func deleteTag(at offsets: IndexSet) {
        viewModel.deleteTag(at: offsets, species: species)
    }
}

#Preview {
    TagsView(species: .Cat)
}
