//
//  AuthenticationViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/27/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()
    
    @Published var isSignedIn = false
    @Published var showLoginSuccess = false
    @Published var signUpForm = ""
    
    
    @Published var shelterID = ""
    @Published var accountType = "volunteer"
    
    @AppStorage("volunteerVideo") var volunteerVideo = ""
    @AppStorage("staffVideo") var staffVideo = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo = ""
//    @AppStorage("accountType") var accountType = "volunteer"

    
    var handle: AuthStateDidChangeListenerHandle?
    var signUpListener: ListenerRegistration?
    var dataListener: ListenerRegistration?

    init() {
        isSignedIn = Auth.auth().currentUser != nil
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                print("User \(user.uid) signed in")
                self?.isSignedIn = true
                self?.fetchSocietyID(forUser: user.uid) { (result) in
                    switch result {
                    case .success(let id):
                        self?.shelterID = id
                        print("Shelter ID: \(id)")
                        self?.setupListeners(theUserID: user.uid)
                    default:
                        print("failed")
//                        print("Shelter ID: \(id)")
                    }
                }
//                self?.setupListeners()
            } else {
                print("User signed out")
                self?.isSignedIn = false
            }
        }
    }
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
            
        }
    }
    
    func removeListeners() {
        signUpListener?.remove()
        dataListener?.remove()
    }
        
    func fetchSignUpForm() {
        signUpListener = Firestore.firestore().collection("Stats").document("AppInformation").addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            if let signUpForm = data["signUpForm"] as? String {
                self?.signUpForm = signUpForm
            }
            if let volunteerVideo = data["volunteerVideo"] as? String {
                self?.volunteerVideo = volunteerVideo
            }
            if let staffVideo = data["staffVideo"] as? String {
                self?.staffVideo = staffVideo
            }
            if let guidedAccessVideo = data["guidedAccessVideo"] as? String {
                self?.guidedAccessVideo = guidedAccessVideo
            }
        }
    }
    

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }


    func verifyPassword(password: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(false)
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                print("Error in reauthentication: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    
    func setupListeners(theUserID: String) {
        
        dataListener = Firestore.firestore().collection("Users").document(theUserID)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching scheduled reports: \(error)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No data found for document")
                    return
                }
                
                self?.shelterID = data["societyID"] as? String ?? ""
//                print(theShelterID)
//                print("This shelter \(self?.shelterID)")
                self?.accountType = data["type"] as? String ?? "volunteer"
//                self?.updateProperties(with: data)
            }
    }
    
//    private func updateProperties(with data: [String: Any]) {
//        DispatchQueue.main.async {
//            self.reportsDay = data["reportsDay"] as? String ?? ""
//            self.reportsEmail = data["reportsEmail"] as? String ?? ""
//            self.earlyReasons = data["earlyReasons"] as? [String] ?? []
//            self.catTags = data["catTags"] as? [String] ?? []
//            self.dogTags = data["dogTags"] as? [String] ?? []
//            self.software = data["software"] as? String ?? ""
//            self.shelter = data["shelter"] as? String ?? ""
//            self.mainFilter = data["mainFilter"] as? String ?? ""
//            self.syncFrequency = data["syncFrequency"] as? String ?? ""
//            self.apiKey = data["apiKey"] as? String ?? ""
//            self.secondarySortOptions = data["secondarySortOptions"] as? [String] ?? []
//            self.groupOptions = data["groupOptions"] as? [String] ?? []
//        }
//    }
    
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

    func updatePassword(oldPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }

        // Create credential with existing user email and provided old password
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        
        // Reauthenticate user
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                print("Error in reauthentication: \(error.localizedDescription)")
                // Handle error and show an alert to the user
                return
            }
            
            // If reauthentication successful, proceed with password update
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    print("Error updating password: \(error.localizedDescription)")
                    // Handle error and show an alert to the user
                } else {
                    print("Password updated successfully!")
                    // Show some confirmation message to the user
                }
            }
        }
    }
}
