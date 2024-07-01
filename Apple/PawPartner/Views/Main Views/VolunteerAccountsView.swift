import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AlertToast

struct Volunteer: Identifiable {
    var id: String
    var name: String
    var email: String
}

struct VolunteerAccountsView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showToast = false
    @State private var volunteers: [Volunteer] = []
//    @AppStorage("societyID") var storedSocietyID: String = ""
    
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    var body: some View {
        Form {
            Section("Add Volunteer") {
                TextField("Volunteer Name", text: $name)
                TextField("Volunteer Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                Button("Send Invite") {
                    sendInvite()
                }
            }
            Section("Volunteers") {
                List {
                    ForEach(volunteers) { volunteer in
                        HStack {
                            Text(volunteer.name)
                            Text(" (\(volunteer.email))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteVolunteer)
                }
            }
            Section("Volunteer Settings") {
                Toggle("Geo-restrict Volunteer Accounts", isOn: .constant(true))
                    .tint(.blue)
            }
        }
        .onAppear {
            fetchVolunteers()
        }
        .toast(isPresenting: $showingAlert) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: alertMessage)
        }
        .toast(isPresenting: $showToast) {
            AlertToast(type: .loading, title: "Sending Invite...")
        }
    }

    private func sendInvite() {
        showToast = true
        let password = generateRandomPassword()
        
        guard let url = URL(string: "https://us-central1-pawpartnerdevelopment.cloudfunctions.net/VolunteerInvite") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "shelterID": authViewModel.shelterID
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.alertMessage = "Error sending invite: \(error.localizedDescription)"
                self.showingAlert = true
                self.showToast = false
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                self.alertMessage = "Invite sent successfully!"
                self.showingAlert = true
                self.name = ""
                self.email = ""
                self.showToast = false
                self.fetchVolunteers() // Refresh the list after adding a new volunteer
            } else {
                self.alertMessage = "Failed to send invite."
                self.showingAlert = true
                self.showToast = false
            }
        }.resume()
    }


    private func generateRandomPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func sendEmailInvite(name: String, email: String, password: String) {
        guard let url = URL(string: "https://us-central1-humanesociety-21855.cloudfunctions.net/VolunteerInvite") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.alertMessage = "Error sending email invite: \(error.localizedDescription)"
                self.showingAlert = true
                self.showToast = false
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                self.alertMessage = "Email invite sent successfully!"
                self.showingAlert = true
                self.showToast = false
            } else {
                self.alertMessage = "Failed to send email invite."
                self.showingAlert = true
                self.showToast = false
            }
        }.resume()
    }


    private func fetchVolunteers() {
        let db = Firestore.firestore()
        db.collection("Users")
            .whereField("societyID", isEqualTo: authViewModel.shelterID)
            .whereField("type", isEqualTo: "volunteer")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    self.alertMessage = "Error fetching volunteers: \(error.localizedDescription)"
                    self.showingAlert = true
                } else {
                    self.volunteers = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return Volunteer(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "",
                            email: data["email"] as? String ?? ""
                        )
                    } ?? []
                }
            }
    }

    private func deleteVolunteer(at offsets: IndexSet) {
        offsets.forEach { index in
            let volunteer = volunteers[index]
            let db = Firestore.firestore()
            db.collection("Users").document(volunteer.id).delete { error in
                if let error = error {
                    self.alertMessage = "Error deleting volunteer: \(error.localizedDescription)"
                    self.showingAlert = true
                } else {
//                    self.callDeleteUserFunction(uid: volunteer.id) // Call cloud function to delete from Firebase Auth
                    self.volunteers.remove(at: index)
                }
            }
        }
    }
    
//    private func callDeleteUserFunction(uid: String) {
//        let functions = Functions.functions()
//        functions.httpsCallable("deleteUser").call(["uid": uid]) { result, error in
//            if let error = error {
//                self.alertMessage = "Error deleting user from Firebase Auth: \(error.localizedDescription)"
//                self.showingAlert = true
//            } else {
//                self.alertMessage = "User successfully deleted from Firebase Auth"
//                self.showingAlert = true
//            }
//        }
//    }
}
