import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AlertToast

struct VolunteerAccountsView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showToast = false
    @AppStorage("societyID") var storedSocietyID: String = ""

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
                
            }
            Section("Volunteer Settings") {
                Toggle("Geo-restrict Volunteer Accounts", isOn: .constant(true))
                    .tint(.blue)
            }
        }
//        .alert(isPresented: $showingAlert) {
//            Alert(title: Text("Invite Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//        }
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
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.alertMessage = "Error: \(error.localizedDescription)"
                self.showingAlert = true
                self.showToast = false
            } else if let authResult = authResult {
                let user = authResult.user
                let db = Firestore.firestore()
                db.collection("Users").document(user.uid).setData([
                    "name": name,
                    "email": email,
                    "societyID": storedSocietyID,
                    "type": "volunteer"
                ]) { error in
                    if let error = error {
                        self.alertMessage = "Error saving user to Firestore: \(error.localizedDescription)"
                        self.showingAlert = true
                        self.showToast = false
                    } else {
                        self.alertMessage = "Invite sent successfully!"
                        self.showingAlert = true
                        self.name = ""
                        self.email = ""
                        self.showToast = false
                        self.sendEmailInvite(name: name, email: email, password: password)
                    }
                }
            }
        }
    }

    private func generateRandomPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func sendEmailInvite(name: String, email: String, password: String) {
        guard let url = URL(string: "https://<YOUR_CLOUD_FUNCTION_URL>") else { return }
        
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
}
