import FirebaseFirestore
import SwiftUI
import Kingfisher

struct AddNoteView: View {
    @ObservedObject var viewModel = AddNoteViewModel()
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    let animal: Animal
    @Environment(\.dismiss) var dismiss
    @State private var note = ""
    @FocusState private var isNoteFieldFocused: Bool
    @State private var selectedTags = Set<String>()
    
    var gridLayout: [GridItem] {
        [GridItem(.adaptive(minimum: 200))]
    }
    
    var body: some View {
        Form {
            Section("Notes") {
                TextEditor(text: $note)
                    .focused($isNoteFieldFocused)
            }
            
            
            if animal.animalType == .Cat && !settingsViewModel.catTags.isEmpty {
                Section("Tags") {
                    HStack {
                        ScrollView {
                            LazyVGrid(columns: gridLayout) {
                                ForEach(settingsViewModel.catTags, id: \.self) { tag in
                                    Text(tag)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 5)
                                        .background(selectedTags.contains(tag) ? Color(red: 144/255, green: 238/255, blue: 144/255) : .black.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(.secondary)
                                        .onTapGesture {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                }
                            }

                        
                        }
                    }
                    .frame(height: 175)
                }
            } else if animal.animalType == .Dog && !settingsViewModel.dogTags.isEmpty {
                Section("Tags") {
                    HStack {
                        ScrollView {
                            LazyVGrid(columns: gridLayout) {
                                ForEach(settingsViewModel.dogTags, id: \.self) { tag in
                                    Text(tag)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 5)
                                        .background(selectedTags.contains(tag) ? Color(red: 144/255, green: 238/255, blue: 144/255) : .black.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(.secondary)
                                        .onTapGesture {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                }
                            }

                        
                        }
                    }
                    .frame(height: 175)

                }
            }
            
            
            Section {
                Button(action: saveNote) {
                    Text("Save Note")
                        .onTapGesture(perform: saveNote)
                }
            }
        }
        .onTapGesture {
            isNoteFieldFocused = false
        }
        .navigationTitle("Add Note About \(animal.name)")
        .onAppear {
            isNoteFieldFocused = true
        }
    }
    
    private func saveNote() {
        viewModel.createNote(for: animal, note: note, tags: Array(selectedTags))
        dismiss()
        animalViewModel.toastAddNote.toggle()
    }
}

    
   


#Preview {
    AddNoteView(viewModel: AddNoteViewModel(), animalViewModel: AnimalViewModel.shared, animal: Animal.dummyAnimal)
}
