import SwiftUI
import FirebaseFirestore

struct VolunteerDetailView: View {
    var volunteer: Volunteer
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        Form {
            Section("Name (tap to edit)") {
                TextField("Name", text: $name)
                    .onChange(of: name) { newName in
                        updateVolunteerName(newName: newName)
                    }
            }
            Section("Email") {
                Text(volunteer.email)
            }
        }
        .onAppear {
            name = volunteer.name
        }
    }

    private func updateVolunteerName(newName: String) {
        let db = Firestore.firestore()
        db.collection("Users").document(volunteer.id).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                print("Name updated successfully!")
            }
        }
    }
}

