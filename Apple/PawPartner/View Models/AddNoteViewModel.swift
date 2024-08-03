//
//  AddNoteViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/24/23.
//

import SwiftUI
import FirebaseFirestore
import Foundation

class AddNoteViewModel: ObservableObject {
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    func createNote(for animal: Animal, note: String, tags: [String], user: String?) {
        let db = Firestore.firestore()
        
        // Create a new note
        let id = UUID().uuidString
        let newNote = Note(id: id, date: Date().timeIntervalSince1970, note: note)
        
        // Convert newNote to a dictionary
        let noteDict: [String: Any] = [
            "id": newNote.id,
            "date": newNote.date,
            "note": newNote.note.trimmingCharacters(in: .whitespacesAndNewlines),
            "user": user as Any
        ]
        
        // Start a Firestore transaction
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let animalDocument = db.collection("Societies").document(self.authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)
            
            // Attempt to retrieve the animal document
            let animalDocumentSnapshot = try? transaction.getDocument(animalDocument)

            // Update tags counts
            var newTags: [String: Int] = animalDocumentSnapshot?.data()?["tags"] as? [String: Int] ?? [:]
            for tag in tags {
                newTags[tag, default: 0] += 1
            }

            // Perform the updates
            transaction.updateData(["notes": FieldValue.arrayUnion([noteDict]), "tags": newTags], forDocument: animalDocument)

            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
            }
        }
    }

}
