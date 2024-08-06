import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SafariServices

class LoginViewModel: ObservableObject {
    @Published var showNewShelterForm = false
    @Published var showTutorials = false
    @Published var email = ""
    @Published var password = ""
    @Published var showLoginError = false
    @Published var loginError = ""
    @Published var isLoginInProgress = false
    @Published var newShelterForm = ""
    @Published var tutorialsURL = ""
    @Published var showVideo = false
    
    @AppStorage("lastSync") var lastSync: String = ""
    
    var loginListener: ListenerRegistration?
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func login() {
        isLoginInProgress = true
        Auth.auth().signIn(withEmail: self.email, password: self.password) { authResult, error in
            self.isLoginInProgress = false
            if let error = error {
                print("Error logging in user: \(error.localizedDescription)")
                self.loginError = error.localizedDescription
                self.showLoginError.toggle()
                return
            }
            self.fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { result in
                switch result {
                case .success(let societyID):
                    print("User signed in successfully")
                    print("SocietyID: \(societyID)")
                case .failure(let error):
                    print("Error fetching societyID: \(error)")
                }
            }
        }
    }
    
    func fetchSocietyID(forUser userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("Users").document(userID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists, let data = document.data(),
                   let societyID = data["societyID"] as? String {
                    completion(.success(societyID))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "SocietyID not found"])))
                }
            }
        }
    }

    func fetchSignUpForm() {
        print("fetching urls")
        loginListener = Firestore.firestore().collection("Stats").document("AppInformation").addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            DispatchQueue.main.async {
                print("setting urls")
                self.newShelterForm = data["signUpForm"] as? String ?? "a"
                self.tutorialsURL = data["tutorialsURL"] as? String ?? "b"
                print(self.tutorialsURL)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
