import AlertToast
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

struct LoginView: View {
    @State private var showNewShelterForm = false
    @State private var showTutorials = false
    @State private var email = ""
    @State private var password = ""
    @State private var showLoginError = false
    @State private var loginError = ""
    @State private var isLoginInProgress = false
    @State private var newShelterForm = ""
    @State private var tutorialsURL = ""

    @AppStorage("lastSync") var lastSync: String = ""
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    @State private var showVideo = false

    var loginListener: ListenerRegistration?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                    }
                    Spacer() // Top spacer
                    Image("Dog")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.3 : geometry.size.width * 0.9)
                    
                        .onAppear {
                            lastSync = dateFormatter.string(from: Date())
                        }
                        .padding(.bottom)
                    VStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.headline)
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                        }
                        VStack(alignment: .leading) {
                            Text("Password")
                                .font(.headline)
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        Button("Login", action: {
                            isLoginInProgress = true
                            Auth.auth().signIn(withEmail: self.email, password: self.password) { authResult, error in
                                isLoginInProgress = false
                                if let error = error {
                                    print("Error logging in user: \(error.localizedDescription)")
                                    loginError = error.localizedDescription
                                    showLoginError.toggle()
                                    return
                                }
                                fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
                                    switch result {
                                    case .success(let societyID):
                                        print("User signed in successfully")
                                        print("SocietyID: \(societyID)")
                                    case .failure(let error):
                                        print("Error fetching societyID: \(error)")
                                    }
                                }
                            }
                        })
                        .font(.largeTitle)
                        .buttonStyle(.bordered)
                        .fontWeight(.bold)
                        .tint(.customBlue)
                        HStack {
                            if let url = URL(string: newShelterForm) {
                                Button(action: {
                                    showNewShelterForm = true
                                }) {
                                    Text("Create New Shelter")
                                }
                                .sheet(isPresented: $showNewShelterForm) {
                                    SafariView(url: url)
                                }
                            } else {
//                                Text("Invalid URL")
                            }
                            if let url = URL(string: tutorialsURL) {
                                Button(action: {
                                    showTutorials = true
                                }) {
                                    Text("Tutorials/Documentation")
                                }
                                .sheet(isPresented: $showTutorials) {
                                    SafariView(url: url)
                                }
                            } else {
//                                Text("Invalid URL")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        Text("Please do not share your login with anybody. You can request an additional admin account by emailing me or create volunteer accounts from within the app.")
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 500)
                    Spacer() // Bottom spacer
                    Spacer()
                }
                .frame(minHeight: geometry.size.height * 1.25)
                .padding(.horizontal, 20)
            }
            .background(Color(.systemBackground))
        }
        .edgesIgnoringSafeArea(.bottom)
        .toast(isPresenting: $showLoginError, duration: 3) {
            AlertToast(type: .error(.red), title: "Your username or password is incorrect.")
        }
        .toast(isPresenting: $isLoginInProgress) {
            AlertToast(type: .loading)
        }
        .onAppear {
            fetchSignUpForm()
        }
        .onDisappear {
            loginListener?.remove()
        }
    }

    func fetchSocietyID(forUser userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("Users").document(userID).getDocument { (document, error) in
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
        Firestore.firestore().collection("Stats").document("AppInformation").addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            DispatchQueue.main.async {
                self.newShelterForm = data["signUpForm"] as? String ?? ""
                self.tutorialsURL = data["tutorialsURL"] as? String ?? ""
            }
        }
    }
}
