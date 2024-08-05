import SwiftUI
import Kingfisher
import FirebaseStorage
import FirebaseFirestore

struct ViewInfoView: View {
    let animal: Animal
    @State private var areNotesExpanded: Bool = true
    @State private var areLogsExpanded: Bool = true
    @State private var areStatsExpanded: Bool = true
    @State private var confirmDeletePhoto: Bool = false
    @State private var confirmDeleteTag: Bool = false
    @State private var isFullScreen = false
    @State private var selectedImageIndex = 0
    @State private var tagToDelete: String? = nil
    @State private var photos: [Photo] = []
    @State private var tags: [String: Int] = [:]
    @State private var notes: [Note] = []

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @AppStorage("adminMode") var adminMode = true
    
    var numberOfColumns: Int = 2
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var sortedNotes: [Note] {
        notes
            .filter { !$0.note.isEmpty }
            .sorted(by: { $0.date > $1.date })
    }
    
    let averageCharactersPerLine: Int = 50
    
    private func estimateLines(for note: String) -> Int {
        return (note.count + averageCharactersPerLine - 1) / averageCharactersPerLine
    }
    
    private func notesForColumn(_ column: Int) -> [Note] {
        let totalLines = sortedNotes.map { estimateLines(for: $0.note) }.reduce(0, +)
        let targetLinesPerColumn = totalLines / numberOfColumns
        var currentLines = Array(repeating: 0, count: numberOfColumns)
        var columnNotes = Array(repeating: [Note](), count: numberOfColumns)
        
        for note in sortedNotes {
            let noteLines = estimateLines(for: note.note)
            if let columnIndex = currentLines.indices.min(by: { currentLines[$0] < currentLines[$1] && currentLines[$0] + noteLines <= targetLinesPerColumn }) {
                columnNotes[columnIndex].append(note)
                currentLines[columnIndex] += noteLines
            } else {
                if let columnIndex = currentLines.indices.min(by: { currentLines[$0] < currentLines[$1] }) {
                    columnNotes[columnIndex].append(note)
                    currentLines[columnIndex] += noteLines
                }
            }
        }
        
        return columnNotes[column]
    }
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    @AppStorage("lastSync") var lastSync: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack {
                VStack {
                    Text(animal.name + " ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)
                    
                    HStack {
                        ForEach(topTags(for: animal), id: \.self) { tag in
                            HStack {
                                Text(tag)
                                if authViewModel.accountType == "admin" && adminMode {
                                    Button {
                                        tagToDelete = tag
                                        confirmDeleteTag = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                            .font(.body)
                                            .opacity(0.5)
                                    }
                                    .confirmationDialog("Are you sure?", isPresented: $confirmDeleteTag) {
                                        Button("I'm sure", role: .destructive) {
                                            if let tag = tagToDelete {
                                                deleteTag(tag: tag)
                                            }
                                            tagToDelete = nil // Reset the tag to delete
                                        }
                                        Button("Cancel", role: .cancel) {
                                            tagToDelete = nil // Reset the tag to delete
                                        }
                                    } message: {
                                        if let tag = tagToDelete {
                                            Text("Are you sure you want to delete the tag \(tag)? This cannot be undone.")
                                        }
                                    }
                                }
                            }
                            .font(.title3)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0.5, y: 1)
                        }
                    }
                }
                TabView(selection: $selectedImageIndex) {
                    ForEach(photos.indices, id: \.self) { index in
                        if let url = dailyCacheBustedURL(for: photos[index].url) {
                            ZStack(alignment: .topTrailing) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        ProgressView() // Placeholder while the image loads
                                            .scaledToFill()
                                    }
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .onTapGesture {
                                        self.selectedImageIndex = index
                                        self.isFullScreen = true
                                    }
                                    .tag(index) // Important for selection
                                if authViewModel.accountType == "admin" && adminMode, let host = url.host, host.contains("storage.googleapis.com") {
                                    Button(action: {
                                        confirmDeletePhoto.toggle()
                                    }) {
                                        Image(systemName: "trash")
                                            .padding(10)
                                            .background(Color.white.opacity(0.7))
                                            .clipShape(Circle())
                                            .foregroundStyle(.red)
                                    }
                                    .padding()
                                    .confirmationDialog("Are you sure?", isPresented: $confirmDeletePhoto) {
                                        Button("I'm sure", role: .destructive) {
                                            deleteImage(urlString: photos[selectedImageIndex].privateURL)
                                        }
                                    } message: {
                                        Text("Are you sure you want to delete this photo? This cannot be undone.")
                                    }
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .shadow(radius: 5)
                .frame(height: 400)
                .padding()
                AnimalDetailsSection(animal: animal)

                if !notes.isEmpty {
                    VStack(alignment: .center) {
                        HStack(alignment: .top, spacing: 20) {
                            ForEach(0..<numberOfColumns, id: \.self) { column in
                                VStack(alignment: .center, spacing: 10) {
                                    ForEach(notesForColumn(column).indices, id: \.self) { noteIndex in
                                        if notesForColumn(column)[noteIndex].note != "Added animal to the app" {
                                            NoteView(note: Binding(
                                                get: { notesForColumn(column)[noteIndex] },
                                                set: { notes[noteIndex] = $0 }
                                            ), onDelete: {
                                                deleteNote(noteID: notesForColumn(column)[noteIndex].id)
                                            }, animal: animal)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .padding(.bottom, 50)
                }
                
                
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedImageIndex) {
                    ForEach(photos.indices, id: \.self) { index in
                        if let url = dailyCacheBustedURL(for: photos[index].url) {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .background(Color.white)
                
                Button(action: {
                    isFullScreen = false // This dismisses the full screen cover
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .padding()
                        .foregroundStyle(.red.opacity(0.8))
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding()
                }
            }
            .ignoresSafeArea(.all)
        }
        .onAppear {
            photos = animal.photos // Initialize photos state
            tags = animal.tags ?? [:] // Initialize tags state
            notes = animal.notes // Initialize notes state
        }
    }
    
    private func dailyCacheBustedURL(for urlString: String) -> URL? {
        guard var urlComponents = URLComponents(string: urlString) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: Date())
        
        let queryItem = URLQueryItem(name: "cacheBust", value: dateStamp)
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [queryItem]
        return urlComponents.url
    }
    
    func deleteImage(urlString: String) {
        deleteImageFromFirebase(url: urlString) { result in
            switch result {
            case .success():
                print("Image successfully deleted from Firebase Storage")
                removeImageURLFromFirestore(urlString: urlString, society_id: authViewModel.shelterID, species: animal.animalType.rawValue, animal_id: animal.id)
                photos.removeAll(where: { $0.privateURL == urlString }) // Update state to refresh view
            case .failure(let error):
                print("Error deleting image from Firebase Storage: \(error)")
            }
        }
    }
    
    func deleteTag(tag: String) {
        print("Attempting to delete tag: '\(tag)'")
        
        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)
        
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists, var tags = document.data()?["tags"] as? [String: Int] {
                if tags.keys.contains(tag) {
                    tags.removeValue(forKey: tag)
                    documentRef.updateData(["tags": tags]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Successfully deleted tag: '\(tag)'")
                            self.tags.removeValue(forKey: tag) // Update state to refresh view
                        }
                    }
                } else {
                    print("Tag '\(tag)' not found in the document.")
                }
            } else {
                print("Document does not exist or failed to cast to expected type")
            }
        }
    }

    func deleteNote(noteID: String) {
        print("Attempting to delete note: '\(noteID)'")

        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)
        
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists, var notes = document.data()?["notes"] as? [[String: Any]] {
                if let index = notes.firstIndex(where: { $0["id"] as? String == noteID }) {
                    notes.remove(at: index)
                    documentRef.updateData(["notes": notes]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Successfully deleted note: '\(noteID)'")
                            self.notes.removeAll(where: { $0.id == noteID }) // Update state to refresh view
                        }
                    }
                } else {
                    print("Note '\(noteID)' not found in the document.")
                }
            } else {
                print("Document does not exist or failed to cast to expected type")
            }
        }
    }
    
    func removeImageURLFromFirestore(urlString: String, society_id: String, species: String, animal_id: String) {
        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(society_id).collection("\(species)s").document(animal_id)
        print("LOG: \(documentRef.path)")
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var photos = document.data()?["photos"] as? [[String: Any]] ?? []
                photos.removeAll(where: { $0["privateURL"] as? String == urlString })
                documentRef.updateData(["photos": photos])
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func deleteImageFromFirebase(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference(withPath: url)
        print(storageRef)
        
        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func topTags(for animal: Animal, count: Int = 3) -> [String] {
        let sortedTags = tags.sorted { $0.value > $1.value }
            .map { $0.key }
            .prefix(count)
        
        return Array(sortedTags)
    }
    
    func imageExists(at url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}
