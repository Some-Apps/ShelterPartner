import SwiftUI
import Kingfisher
import FirebaseStorage
import FirebaseFirestore

class ViewInfoViewModel: ObservableObject {
    let animal: Animal
    @Published var areNotesExpanded: Bool = true
    @Published var areLogsExpanded: Bool = true
    @Published var areStatsExpanded: Bool = true
    @Published var confirmDeletePhoto: Bool = false
    @Published var confirmDeleteTag: Bool = false
    @Published var isFullScreen = false
    @Published var selectedImageIndex = 0
    @Published var tagToDelete: String? = nil
    @Published var photos: [Photo] = []
    @Published var tags: [String: Int] = [:]
    @Published var notes: [Note] = []

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @AppStorage("adminMode") var adminMode = true
    
    var numberOfColumns: Int = 2
    
    var sortedNotes: [Note] {
        notes
            .filter { !$0.note.isEmpty }
            .sorted(by: { $0.date > $1.date })
    }
    
    let averageCharactersPerLine: Int = 50
    
    init(animal: Animal) {
        self.animal = animal
        self.photos = animal.photos
        self.tags = animal.tags ?? [:]
        self.notes = animal.notes
    }
    
    func estimateLines(for note: String) -> Int {
        return (note.count + averageCharactersPerLine - 1) / averageCharactersPerLine
    }
    
    func notesForColumn(_ column: Int) -> [Note] {
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
    
    func dailyCacheBustedURL(for urlString: String) -> URL? {
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
                self.removeImageURLFromFirestore(urlString: urlString, society_id: self.authViewModel.shelterID, species: self.animal.animalType.rawValue, animal_id: self.animal.id)
                self.photos.removeAll(where: { $0.privateURL == urlString }) // Update state to refresh view
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
