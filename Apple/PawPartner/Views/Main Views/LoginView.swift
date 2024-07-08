//
//  LoginView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/27/23.
//

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
    @State private var showSafariView = false
    @State private var email = ""
    @State private var password = ""
    @State private var showLoginError = false
    @State private var loginError = ""
    @State private var isLoginInProgress = false  // New property
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("lastSync") var lastSync: String = ""
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    @State private var showVideo = false
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Image("Dog")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width * 0.3, height: geometry.size.width * 0.3)
                        .cornerRadius(20)
                        .onAppear {
                            lastSync = dateFormatter.string(from: Date())
                        }
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
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
                                        let tempSocietyID = societyID
//                                        storedSocietyID = tempSocietyID
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
//                    Text("In order to create an account, please fill out the following form and I will get back to you as soon as possible.")
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
                    HStack {
                        if let url = URL(string: authViewModel.signUpForm) {
                            Button(action: {
                                showSafariView = true
                            }) {
                                Text("Request Account")
                            }
                            .sheet(isPresented: $showSafariView) {
                                SafariView(url: url)
                            }
                        } else {
                            Text("Invalid URL")
                        }
                        Button {
                            showVideo = true
                        } label: {
                            Text("App Walkthrough")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    Text("This app is not meant to be used on personal devices. If you are a volunteer, this app should only be used on a shelter owned iPad. The iPhone version of this app is only for animal shelter staff.")
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: 500)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .padding(.top, geometry.safeAreaInsets.top)
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
            authViewModel.fetchSignUpForm()
        }
        .onDisappear {
            authViewModel.removeListeners()
        }
        .sheet(isPresented: $showVideo) {
            YoutubeVideoView(videoID: authViewModel.staffVideo)
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
}
