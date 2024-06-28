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
    @State private var name = ""
    @FocusState private var isNoteFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    @State private var selectedTags = Set<String>()
    @AppStorage("requireName") var requireName = false

    var gridLayout: [GridItem] {
        [GridItem(.adaptive(minimum: 200))]
    }
    
    var body: some View {
        Form {
            if requireName {
                Section("Name of Volunteer") {
                    TextField("Name", text: $name)
                        .focused($isNameFieldFocused)
                }
            }
            
            Section("Note for \(animal.name)") {
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
                .disabled(requireName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedTags.isEmpty))
            }
//            Section("This ad supports the future development of PawPartner") {
//                           GeometryReader { geometry in
//                               BannerAdView()
//                                   .frame(width: geometry.size.width, height: 100)
//                           }
//                           .frame(height: 100) // Set height to avoid expanding the section
//                       }
        }
        .onTapGesture {
            isNoteFieldFocused = false
            isNameFieldFocused = false
        }
        .navigationTitle("Add Note About \(animal.name)")
        .onAppear {
            if requireName {
                isNameFieldFocused = true
            } else {
                isNoteFieldFocused = true
            }
        }
    }
    
    private func saveNote() {
        viewModel.createNote(for: animal, note: note, tags: Array(selectedTags), user: name)
        dismiss()
        animalViewModel.toastAddNote.toggle()
    }
}

    
   


#Preview {
    AddNoteView(viewModel: AddNoteViewModel(), animalViewModel: AnimalViewModel.shared, animal: Animal.dummyAnimal)
}


//struct BannerAdView: UIViewRepresentable {
//    func makeUIView(context: Context) -> GADBannerView {
//        let bannerView = GADBannerView(adSize: GADAdSizeLargeBanner)
//        bannerView.adUnitID = "ad_unit"
//        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
//        bannerView.load(GADRequest())
//        return bannerView
//    }
//
//    func updateUIView(_ uiView: GADBannerView, context: Context) {}
//}
