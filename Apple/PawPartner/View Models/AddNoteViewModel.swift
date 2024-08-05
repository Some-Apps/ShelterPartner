import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class AddNoteViewModel: ObservableObject {
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    func createNote(for animal: Animal, note: String, tags: [String], user: String?, avatarItem: PhotosPickerItem?, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let noteId = UUID().uuidString
        let newNote = Note(id: noteId, date: Date().timeIntervalSince1970, note: note)
        
        // Upload image if avatarItem is provided
        if let avatarItem = avatarItem {
            uploadImage(avatarItem: avatarItem, shelterID: authViewModel.shelterID, animalID: animal.id, noteID: noteId) { result in
                switch result {
                case .success(let url):
                    let photoDict: [String: Any] = [
                        "url": url.absoluteString,
                        "privateURL": "\(self.authViewModel.shelterID)/\(animal.id)/\(noteId).jpeg",
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    self.addPhotoToFirestore(db: db, animal: animal, photoDict: photoDict) { success in
                        if success {
                            self.addNoteToFirestore(db: db, animal: animal, newNote: newNote, tags: tags, user: user, completion: completion)
                        } else {
                            completion(false)
                        }
                    }
                case .failure(let error):
                    print("Failed to upload image: \(error)")
                    completion(false)
                }
            }
        } else {
            self.addNoteToFirestore(db: db, animal: animal, newNote: newNote, tags: tags, user: user, completion: completion)
        }
    }
    
    private func uploadImage(avatarItem: PhotosPickerItem, shelterID: String, animalID: String, noteID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated"])))
            return
        }

        let storageRef = Storage.storage().reference()
        let storagePath = "\(shelterID)/\(animalID)/\(noteID).jpeg"
        let storageReference = storageRef.child(storagePath)
        
        Task {
            do {
                if let imageData = try await avatarItem.loadTransferable(type: Data.self) {
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    storageReference.putData(imageData, metadata: metadata) { metadata, error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            storageReference.downloadURL { url, error in
                                if let url = url {
                                    completion(.success(url))
                                } else if let error = error {
                                    completion(.failure(error))
                                }
                            }
                        }
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func addPhotoToFirestore(db: Firestore, animal: Animal, photoDict: [String: Any], completion: @escaping (Bool) -> Void) {
        let animalDocument = db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let animalDocumentSnapshot = try? transaction.getDocument(animalDocument)
            var photos: [[String: Any]] = animalDocumentSnapshot?.data()?["photos"] as? [[String: Any]] ?? []
            photos.append(photoDict)
            transaction.updateData(["photos": photos], forDocument: animalDocument)
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(false)
            } else {
                print("Photo successfully added!")
                completion(true)
            }
        }
    }
    
    private func addNoteToFirestore(db: Firestore, animal: Animal, newNote: Note, tags: [String], user: String?, completion: @escaping (Bool) -> Void) {
        let noteDict: [String: Any] = [
            "id": newNote.id,
            "date": newNote.date,
            "note": newNote.note.trimmingCharacters(in: .whitespacesAndNewlines),
            "user": user as Any
        ]

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let animalDocument = db.collection("Societies").document(self.authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)
            
            let animalDocumentSnapshot = try? transaction.getDocument(animalDocument)
            var newTags: [String: Int] = animalDocumentSnapshot?.data()?["tags"] as? [String: Int] ?? [:]
            for tag in tags {
                newTags[tag, default: 0] += 1
            }
            transaction.updateData(["notes": FieldValue.arrayUnion([noteDict]), "tags": newTags], forDocument: animalDocument)
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(false)
            } else {
                print("Note successfully added!")
                completion(true)
            }
        }
    }
}
