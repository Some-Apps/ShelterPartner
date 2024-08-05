import SwiftUI
import PhotosUI
import AlertToast

struct AddNoteView: View {
    @ObservedObject var viewModel = AddNoteViewModel()
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    let animal: Animal
    @Environment(\.dismiss) var dismiss
    @State private var note = ""
    @State private var name = ""
    @FocusState private var isNoteFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    @State private var selectedTags = Set<String>()
    @AppStorage("requireName") var requireName = false
    @AppStorage("allowPhotoUploads") var allowPhotoUploads = true
    @State private var imageItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var showImagePicker = false

    var gridLayout: [GridItem] {
        [GridItem(.adaptive(minimum: 200))]
    }
    
    var body: some View {
        ZStack {
            Form {
                if requireName {
                    if !authViewModel.name.isEmpty {
                        Section("Name of Volunteer") {
                            Text(authViewModel.name)
                                .foregroundStyle(.secondary)
                                .onAppear {
                                    name = authViewModel.name
                                }
                        }
                    } else {
                        Section("Name of Volunteer") {
                            TextField("Name", text: $name)
                                .focused($isNameFieldFocused)
                        }
                    }
                }
                
                Section("Note for \(animal.name)") {
                    TextEditor(text: $note)
                        .focused($isNoteFieldFocused)
                }
                
                if animal.animalType == .Cat && !authViewModel.catTags.isEmpty {
                    Section("Tags") {
                        HStack {
                            ScrollView {
                                LazyVGrid(columns: gridLayout) {
                                    ForEach(authViewModel.catTags, id: \.self) { tag in
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
                } else if animal.animalType == .Dog && !authViewModel.dogTags.isEmpty {
                    Section("Tags") {
                        HStack {
                            ScrollView {
                                LazyVGrid(columns: gridLayout) {
                                    ForEach(authViewModel.dogTags, id: \.self) { tag in
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
                
                if allowPhotoUploads && authViewModel.accountType == "volunteer" {
                    Button(action: {
                        DispatchQueue.main.async {
                            showImagePicker.toggle()
                        }
                    }) {
                        Text("Add Image")
                    }
                    .photosPicker(isPresented: $showImagePicker, selection: $imageItem, matching: .images)
                    .onChange(of: imageItem) { newAvatarItem in
                        Task {
                            if let data = try? await newAvatarItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    image = uiImage
                                }
                            } else {
                                print("Failed")
                            }
                        }
                    }
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    }
                }
                
                Section {
                    Button(action: saveNote) {
                        Text("Save Note")
                            .onTapGesture(perform: saveNote)
                    }
                    .disabled(requireName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedTags.isEmpty && image == nil))
                }
            }
            
            .navigationTitle("Add Note About \(animal.name)")
            .onAppear {
                if requireName {
                    isNameFieldFocused = true
                } else {
                    isNoteFieldFocused = true
                }
            }
            .toast(isPresenting: $isLoading) {
                AlertToast(displayMode: .alert, type: .loading, title: "Saving")
            }
            .onTapGesture(count: 2, perform: {
                isNoteFieldFocused = false
                isNameFieldFocused = false
            })
        }
    }
    
    private func saveNote() {
        isLoading = true
        viewModel.createNote(for: animal, note: note, tags: Array(selectedTags), user: name, avatarItem: imageItem) { success in
            isLoading = false
            if success {
                dismiss()
                animalViewModel.toastAddNote.toggle()
            } else {
                // Handle error (e.g., show an alert)
            }
        }
    }
}
