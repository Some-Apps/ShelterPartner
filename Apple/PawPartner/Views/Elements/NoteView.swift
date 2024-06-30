//
//  NoteView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/24/23.
//

import FirebaseFirestore
import SwiftUI
import Kingfisher

struct NoteView: View {
    let note: Note
    let animal: Animal
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
//    @AppStorage("societyID") var storedSocietyID: String = ""
//    @AppStorage("accountType") var accountType = "volunteer"
    @AppStorage("showNoteDates") var showNoteDates = true

    @State private var confirmDeleteNote = false
    
    var body: some View {
            GroupBox {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            if showNoteDates {
                                Text(dateFormatter.string(from: Date(timeIntervalSince1970: note.date)))
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title3)
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            Text(note.note)
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()

                        if isWithin20Minutes(of: Date(timeIntervalSince1970: note.date)) || (authViewModel.accountType == "admin") {
                            Button {
                                confirmDeleteNote.toggle()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .opacity(0.5)
                            }
                            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteNote) {
                                Button("I'm sure", role: .destructive) {
                                    deleteNote()
                                }
                            } message: {
                                Text("Are you sure you want to delete this note? This cannot be undone.")
                            }
                        }
                    }
                }
            }
            .cornerRadius(20)
    }
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    func isWithin20Minutes(of date: Date) -> Bool {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        return interval < 1 * 20 * 60
    }
    
    func deleteNote() {
        // This is the path to the animal
        let animalPath = Firestore.firestore().collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id)

        // Get the document
        animalPath.getDocument { (document, error) in
            if let document = document, document.exists {
                if var notes = document.data()?["notes"] as? [[String: Any]] {
                    // Find the index of the note with the matching id
                    if let index = notes.firstIndex(where: { $0["id"] as? String == note.id }) {
                        // Remove the note from the array
                        notes.remove(at: index)
                        
                        // Update the document
                        animalPath.updateData(["notes": notes]) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                            } else {
                                print("Document successfully updated")
                            }
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }


}
